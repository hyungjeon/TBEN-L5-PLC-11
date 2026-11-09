// 1 instance cho mỗi IO-Link master (AL1100). Khoá + hàng đợi FIFO: tại 1 thời điểm chỉ 1 IOL_CALL
// chạy trên record CAP, các client (FB_IolCall) lần lượt theo thứ tự Submit -> công bằng giữa các device.
FUNCTION_BLOCK FB_IolMaster
VAR_INPUT
    itfRec   : ITF_IolRecordAccess;                // transport thật (FB_PnRecordAccess) hoặc mock
    xEnable  : BOOL := TRUE;                       // FALSE: không lấy request mới từ hàng đợi
    dwId     : DWORD;                              // ID submodule CAP (CommFB.SUBSLOT_ID), mock bỏ qua
    tTimeout : TIME := GVL_IolConst.tCALL_TIMEOUT;
    xReset   : BOOL;                               // xoá hàng đợi, thoát STUCK
END_VAR
VAR_OUTPUT
    eState          : E_IolCallState;
    xBusy           : BOOL;
    usiActiveClient : USINT;                       // handle đang chạy, 0 = rảnh
    uiQueueCount    : UINT;
    udiCallCount    : UDINT;                       // số lần gọi OK
    udiErrCount     : UDINT;                       // số lần gọi lỗi
    xNoTransport    : BOOL;                        // itfRec chưa gán
END_VAR
VAR
    aQueue     : ARRAY[0..GVL_IolConst.iQUEUE_SIZE - 1] OF USINT;   // FIFO handle
    iHead      : INT;
    iCount     : INT;
    aReq       : ARRAY[1..GVL_IolConst.iQUEUE_SIZE] OF ST_IolRequest;
    aRes       : ARRAY[1..GVL_IolConst.iQUEUE_SIZE] OF ST_IolResult;
    axPending  : ARRAY[1..GVL_IolConst.iQUEUE_SIZE] OF BOOL;        // đã Submit, chưa có kết quả
    axResReady : ARRAY[1..GVL_IolConst.iQUEUE_SIZE] OF BOOL;        // kết quả chờ client Poll
    axCancel   : ARRAY[1..GVL_IolConst.iQUEUE_SIZE] OF BOOL;        // client đã bỏ, huỷ kết quả
    usiHandles : USINT;                                             // số client đã Register
    abTx       : ARRAY[0..GVL_IolConst.uiMAX_REC - 1] OF BYTE;      // khung gửi (Watch khi test)
    abRx       : ARRAY[0..GVL_IolConst.uiMAX_REC - 1] OF BYTE;      // khung nhận
    uiTxLen    : UINT;
    uiRxLen    : UINT;
    xWrReq     : BOOL;          // REQ cho chu kỳ sau (state machine quyết định)
    xRdReq     : BOOL;
    xWrDone    : BOOL;
    xWrBusy    : BOOL;
    xWrErr     : BOOL;
    dwWrStatus : DWORD;
    xRdValid   : BOOL;
    xRdBusy    : BOOL;
    xRdErr     : BOOL;
    dwRdStatus : DWORD;
    iRdLen     : INT;
    tonTimeout : TON;
    tonRetry   : TON;
    tonStuck   : TON;
    iRetry     : INT;
    stCur      : ST_IolResult;  // kết quả request đang chạy
    stEmpty    : ST_IolResult;
    i          : INT;
END_VAR

(*---IMPL---*)
// ---------- 0. Reset: trả lỗi LOCK cho mọi request đang chờ, về IDLE ----------
IF xReset THEN
    xWrReq := FALSE;
    xRdReq := FALSE;
    FOR i := 1 TO GVL_IolConst.iQUEUE_SIZE DO
        IF axPending[i] AND NOT axCancel[i] THEN
            aRes[i] := stEmpty;
            aRes[i].xError := TRUE;
            aRes[i].eErrSource := E_IolErrSource.LOCK;
            axResReady[i] := TRUE;
        END_IF
        axPending[i] := FALSE;
        axCancel[i]  := FALSE;
    END_FOR
    iHead := 0;
    iCount := 0;
    usiActiveClient := 0;
    tonTimeout(IN := FALSE);
    tonRetry(IN := FALSE);
    tonStuck(IN := FALSE);
    eState := E_IolCallState.IDLE;
END_IF

// ---------- 1. Gọi transport đúng 1 lần mỗi chu kỳ, REQ do chu kỳ trước quyết định ----------
xNoTransport := (itfRec = 0);
IF NOT xNoTransport THEN
    itfRec.Write(xReq := xWrReq, dwId := dwId, iIndex := UINT_TO_INT(GVL_IolConst.uiCAP_INDEX),
                 iLen := UINT_TO_INT(uiTxLen), pData := ADR(abTx),
                 xDone => xWrDone, xBusy => xWrBusy, xError => xWrErr, dwStatus => dwWrStatus);
    itfRec.Read(xReq := xRdReq, dwId := dwId, iIndex := UINT_TO_INT(GVL_IolConst.uiCAP_INDEX),
                iMLen := UINT_TO_INT(GVL_IolConst.uiMAX_REC), pData := ADR(abRx),
                xValid => xRdValid, xBusy => xRdBusy, xError => xRdErr, dwStatus => dwRdStatus, iLen => iRdLen);
ELSE
    xWrDone := FALSE; xWrBusy := FALSE; xWrErr := FALSE;
    xRdValid := FALSE; xRdBusy := FALSE; xRdErr := FALSE;
END_IF

// ---------- 2. Timeout tổng của 1 request ----------
tonTimeout(IN := eState = E_IolCallState.WRITE_REQ OR eState = E_IolCallState.RETRY_WR
              OR eState = E_IolCallState.READ_WAIT OR eState = E_IolCallState.READ_REQ,
           PT := tTimeout);
IF tonTimeout.Q THEN
    xWrReq := FALSE;
    xRdReq := FALSE;
    tonStuck(IN := FALSE);
    eState := E_IolCallState.TIMEOUT;
END_IF

// ---------- 3. State machine IOL_CALL ----------
CASE eState OF
    E_IolCallState.IDLE:
        xWrReq := FALSE;
        xRdReq := FALSE;
        IF xEnable AND iCount > 0 THEN
            usiActiveClient := aQueue[iHead];
            iHead  := (iHead + 1) MOD GVL_IolConst.iQUEUE_SIZE;
            iCount := iCount - 1;
            IF axCancel[usiActiveClient] OR NOT axPending[usiActiveClient] THEN
                // client đã bỏ trước khi tới lượt: bỏ qua, không gửi
                axCancel[usiActiveClient]  := FALSE;
                axPending[usiActiveClient] := FALSE;
                usiActiveClient := 0;
            ELSE
                stCur  := stEmpty;
                iRetry := 0;
                BuildFrame();
                IF xNoTransport THEN
                    stCur.eErrSource   := E_IolErrSource.PNIO;
                    stCur.dwPnioStatus := GVL_IolConst.dwSTAT_NO_TRANSPORT;
                    eState := E_IolCallState.ERROR;
                ELSE
                    xWrReq := TRUE;
                    eState := E_IolCallState.WRITE_REQ;
                END_IF
            END_IF
        END_IF

    E_IolCallState.WRITE_REQ:
        IF xWrDone THEN
            xWrReq := FALSE;
            tonRetry(IN := FALSE);
            eState := E_IolCallState.READ_WAIT;
        ELSIF xWrErr THEN
            xWrReq := FALSE;
            IF F_IolIsPnioBusy(dwWrStatus) AND iRetry < GVL_IolConst.iMAX_RETRY THEN
                iRetry := iRetry + 1;
                tonRetry(IN := FALSE);
                eState := E_IolCallState.RETRY_WR;
            ELSE
                stCur.eErrSource   := E_IolErrSource.PNIO;
                stCur.dwPnioStatus := dwWrStatus;
                eState := E_IolCallState.ERROR;
            END_IF
        END_IF

    E_IolCallState.RETRY_WR:
        tonRetry(IN := TRUE, PT := GVL_IolConst.tRETRY_DELAY);
        IF tonRetry.Q THEN
            tonRetry(IN := FALSE);
            xWrReq := TRUE;
            eState := E_IolCallState.WRITE_REQ;
        END_IF

    E_IolCallState.READ_WAIT:
        tonRetry(IN := TRUE, PT := GVL_IolConst.tRETRY_DELAY);
        IF tonRetry.Q THEN
            tonRetry(IN := FALSE);
            xRdReq := TRUE;
            eState := E_IolCallState.READ_REQ;
        END_IF

    E_IolCallState.READ_REQ:
        IF xRdValid THEN
            xRdReq  := FALSE;
            uiRxLen := INT_TO_UINT(MAX(iRdLen, 0));
            IF ParseResponse() THEN
                eState := E_IolCallState.DONE;
            ELSE
                eState := E_IolCallState.ERROR;
            END_IF
        ELSIF xRdErr THEN
            xRdReq := FALSE;
            IF F_IolIsPnioBusy(dwRdStatus) AND iRetry < GVL_IolConst.iMAX_RETRY THEN
                iRetry := iRetry + 1;                 // ISDU chưa xong trên master -> đọc lại sau
                tonRetry(IN := FALSE);
                eState := E_IolCallState.READ_WAIT;
            ELSE
                stCur.eErrSource   := E_IolErrSource.PNIO;
                stCur.dwPnioStatus := dwRdStatus;
                eState := E_IolCallState.ERROR;
            END_IF
        END_IF

    E_IolCallState.DONE:
        Finish(xErr := FALSE);
        eState := E_IolCallState.IDLE;

    E_IolCallState.ERROR:
        Finish(xErr := TRUE);
        eState := E_IolCallState.IDLE;

    E_IolCallState.TIMEOUT:
        // REQ đã hạ; chờ transport hết BUSY rồi mới cho request mới (tránh chồng record)
        xWrReq := FALSE;
        xRdReq := FALSE;
        tonStuck(IN := TRUE, PT := T#1S);
        IF NOT xWrBusy AND NOT xRdBusy THEN
            tonStuck(IN := FALSE);
            stCur.eErrSource := E_IolErrSource.TIMEOUT;
            Finish(xErr := TRUE);
            eState := E_IolCallState.IDLE;
        ELSIF tonStuck.Q THEN
            tonStuck(IN := FALSE);
            stCur.eErrSource := E_IolErrSource.TIMEOUT;
            Finish(xErr := TRUE);
            eState := E_IolCallState.STUCK;
        END_IF

    E_IolCallState.STUCK:
        // chỉ thoát bằng xReset (bước 0)
        xWrReq := FALSE;
        xRdReq := FALSE;
END_CASE

xBusy := (eState <> E_IolCallState.IDLE);
uiQueueCount := INT_TO_UINT(iCount);

// Tạo khung IOL_CALL (abTx, uiTxLen) cho client đang chạy - layout plan mục 4.2
METHOD PRIVATE BuildFrame
VAR
    h : USINT;
    i : INT;
    n : UINT;
END_VAR

(*---IMPL---*)
h := usiActiveClient;
abTx[0] := GVL_IolConst.usiEXT_FUNC_NUM;
abTx[1] := aReq[h].usiPort;
F_IolSetU16BE(ADR(abTx), 2, GVL_IolConst.uiFI_INDEX);
abTx[4] := TO_BYTE(aReq[h].eService);
F_IolSetU16BE(ADR(abTx), 5, aReq[h].uiIndex);
abTx[7] := aReq[h].usiSubindex;
uiTxLen := GVL_IolConst.uiHDR_LEN;
IF aReq[h].eService = E_IolService.WRITE THEN
    n := MIN(aReq[h].uiLen, GVL_IolConst.uiMAX_DATA);
    FOR i := 0 TO UINT_TO_INT(n) - 1 DO
        abTx[GVL_IolConst.uiHDR_LEN + INT_TO_UINT(i)] := aReq[h].abData[i];
    END_FOR
    uiTxLen := GVL_IolConst.uiHDR_LEN + n;
END_IF

// Kiểm khung phản hồi abRx và điền stCur. Layout lỗi (Control 0x80, byte 5..8) là GIẢ ĐỊNH theo spec PNO,
// phải đối chiếu manual AL1100 khi test thật - chỉ cần sửa trong method này.
METHOD PRIVATE ParseResponse : BOOL
VAR
    h : USINT;
    i : INT;
    n : UINT;
END_VAR

(*---IMPL---*)
ParseResponse := FALSE;
h := usiActiveClient;

IF uiRxLen < 5
   OR abRx[0] <> GVL_IolConst.usiEXT_FUNC_NUM
   OR abRx[1] <> aReq[h].usiPort
   OR F_IolGetU16BE(ADR(abRx), 2) <> GVL_IolConst.uiFI_INDEX THEN
    stCur.eErrSource := E_IolErrSource.FRAME;
    RETURN;
END_IF

IF abRx[4] = GVL_IolConst.usiCTRL_ERROR THEN
    IF uiRxLen >= 7 THEN
        stCur.uiIolMasterErr := F_IolGetU16BE(ADR(abRx), 5);
    END_IF
    IF uiRxLen >= 9 THEN
        stCur.uiIolDevErr := F_IolGetU16BE(ADR(abRx), 7);
    END_IF
    IF stCur.uiIolDevErr <> 0 THEN
        stCur.eErrSource := E_IolErrSource.IOL_DEVICE;
    ELSE
        stCur.eErrSource := E_IolErrSource.IOL_MASTER;
    END_IF
    RETURN;
END_IF

IF uiRxLen < GVL_IolConst.uiHDR_LEN
   OR abRx[4] <> TO_BYTE(aReq[h].eService)
   OR F_IolGetU16BE(ADR(abRx), 5) <> aReq[h].uiIndex
   OR abRx[7] <> aReq[h].usiSubindex THEN
    stCur.eErrSource := E_IolErrSource.FRAME;
    RETURN;
END_IF

n := MIN(uiRxLen - GVL_IolConst.uiHDR_LEN, GVL_IolConst.uiMAX_DATA);
FOR i := 0 TO UINT_TO_INT(n) - 1 DO
    stCur.abData[i] := abRx[GVL_IolConst.uiHDR_LEN + INT_TO_UINT(i)];
END_FOR
stCur.uiLen := n;
ParseResponse := TRUE;

// Giao kết quả stCur cho client đang chạy (bỏ nếu client đã Cancel), giải phóng khoá
METHOD PRIVATE Finish
VAR_INPUT
    xErr : BOOL;
END_VAR
VAR
    h : USINT;
END_VAR

(*---IMPL---*)
h := usiActiveClient;
IF h >= 1 AND h <= GVL_IolConst.iQUEUE_SIZE THEN
    stCur.xError := xErr;
    IF NOT axCancel[h] THEN
        aRes[h] := stCur;
        axResReady[h] := TRUE;
    END_IF
    axCancel[h]  := FALSE;
    axPending[h] := FALSE;
END_IF
IF xErr THEN
    udiErrCount := udiErrCount + 1;
ELSE
    udiCallCount := udiCallCount + 1;
END_IF
usiActiveClient := 0;
xWrReq := FALSE;
xRdReq := FALSE;

(*---IMPL---*)
IF usiHandles < INT_TO_USINT(GVL_IolConst.iQUEUE_SIZE) THEN
    usiHandles := usiHandles + 1;
    Register := usiHandles;
ELSE
    Register := 0;
END_IF

// Client gọi 1 lần để nhận handle 1..iQUEUE_SIZE; 0 = hết chỗ
METHOD Register : USINT

// Đưa request của client vào cuối FIFO; FALSE nếu handle sai, đang có request chờ hoặc hàng đợi đầy
METHOD Submit : BOOL
VAR_INPUT
    hHandle : USINT;
END_VAR
VAR_IN_OUT
    stReq : ST_IolRequest;
END_VAR

(*---IMPL---*)
Submit := FALSE;
IF hHandle < 1 OR hHandle > GVL_IolConst.iQUEUE_SIZE THEN
    RETURN;
END_IF
IF axPending[hHandle] OR iCount >= GVL_IolConst.iQUEUE_SIZE THEN
    RETURN;
END_IF
aReq[hHandle] := stReq;
axResReady[hHandle] := FALSE;
axCancel[hHandle]   := FALSE;
axPending[hHandle]  := TRUE;
aQueue[(iHead + iCount) MOD GVL_IolConst.iQUEUE_SIZE] := hHandle;
iCount := iCount + 1;
Submit := TRUE;

// TRUE khi có kết quả cho handle (chép vào stRes và xoá cờ)
METHOD Poll : BOOL
VAR_INPUT
    hHandle : USINT;
END_VAR
VAR_IN_OUT
    stRes : ST_IolResult;
END_VAR

(*---IMPL---*)
Poll := FALSE;
IF hHandle >= 1 AND hHandle <= GVL_IolConst.iQUEUE_SIZE THEN
    IF axResReady[hHandle] THEN
        stRes := aRes[hHandle];
        axResReady[hHandle] := FALSE;
        Poll := TRUE;
    END_IF
END_IF

// Client bỏ request (vd timeout phía client): request còn trong FIFO bị bỏ qua, đang chạy thì huỷ kết quả
METHOD Cancel
VAR_INPUT
    hHandle : USINT;
END_VAR

(*---IMPL---*)
IF hHandle >= 1 AND hHandle <= GVL_IolConst.iQUEUE_SIZE THEN
    IF axPending[hHandle] THEN
        axCancel[hHandle] := TRUE;
    END_IF
    axResReady[hHandle] := FALSE;
END_IF

