// Giả lập AL1100 + O5D150 cho CODESYS Simulation: nhận khung IOL_CALL qua Write, trả phản hồi qua Read
// theo layout record CAP 0xB400 (plan mục 4.2). Dữ liệu O5D150 lấy theo IODD; có cờ chèn lỗi để test.
FUNCTION_BLOCK FB_MockRecordAccess IMPLEMENTS ITF_IolRecordAccess
VAR_INPUT
    tDelayWr           : TIME  := T#30MS;     // thời gian giả lập WRREC
    tDelayRd           : TIME  := T#30MS;     // thời gian giả lập RDREC
    usiDevPort         : USINT := GVL_IolConst.usiPORT_O5D150;   // port có O5D150 giả lập
    xDevPresent        : BOOL  := TRUE;       // FALSE -> master trả lỗi truyền thông 0x8004
    usiSimAlign        : USINT := 75;         // giá trị Align (index 69) trả về [%]
    // --- Chèn lỗi ---
    xInjPnioErr        : BOOL;                // WRREC trả STATUS DE80B000
    usiInjBusyCount    : USINT;               // số lần RDREC trả "bận" (B5) cho mỗi request
    uiInjDevErr        : UINT;                // <> 0: mọi request trả lỗi device này (vd 16#8023)
    xInjNoResponse     : BOOL;                // không bao giờ xong -> test timeout
    xInjBadFrame       : BOOL;                // phản hồi byte 0 sai -> lỗi FRAME
    xIdx37NotSupported : BOOL;                // index 37 trả 0x8011 như IODD (không khai báo)
    awInjEvent         : ARRAY[0..3] OF WORD; // thêm event bất kỳ vào danh sách index 37 (0 = trống)
END_VAR
VAR_OUTPUT
    udiWrCount    : UDINT;
    udiRdCount    : UDINT;
    usiLastSysCmd : USINT;                    // System Command gần nhất nhận được
    xEvt1Active   : BOOL;                     // Test Event 0x8DFE đang active
    xEvt2Active   : BOOL;                     // Test Event 0x8DFF đang active
END_VAR
VAR
    xInit       : BOOL;
    aStore      : ARRAY[0..19] OF ST_MockParam;
    iStoreCount : INT;
    tonWr       : TON;
    tonRd       : TON;
    xWrActive   : BOOL;
    xWrFinished : BOOL;
    xWrFailed   : BOOL;
    dwWrStat    : DWORD;
    xRdActive   : BOOL;
    xRdFinished : BOOL;
    xRdFailed   : BOOL;
    dwRdStat    : DWORD;
    iRdLenOut   : INT;
    abReq       : ARRAY[0..GVL_IolConst.uiMAX_REC - 1] OF BYTE;
    uiReqLen    : UINT;
    abResp      : ARRAY[0..GVL_IolConst.uiMAX_REC - 1] OF BYTE;
    uiRespLen   : UINT;
    xRespReady  : BOOL;
    usiBusyLeft : USINT;
    abTmp       : ARRAY[0..63] OF BYTE;
END_VAR

(*---IMPL---*)
// Không có xử lý chu kỳ: Write/Read do FB_IolMaster gọi mỗi chu kỳ.
IF NOT xInit THEN
    InitStore();
END_IF

METHOD Write : BOOL
VAR_INPUT
    xReq   : BOOL;
    dwId   : DWORD;
    iIndex : INT;
    iLen   : INT;
    pData  : POINTER TO BYTE;
END_VAR
VAR_OUTPUT
    xDone    : BOOL;
    xBusy    : BOOL;
    xError   : BOOL;
    dwStatus : DWORD;
END_VAR
VAR
    i : INT;
END_VAR

(*---IMPL---*)
IF NOT xInit THEN
    InitStore();
END_IF

IF NOT xReq THEN
    // REQ hạ: sẵn sàng cho request mới
    xWrActive   := FALSE;
    xWrFinished := FALSE;
    xWrFailed   := FALSE;
    tonWr(IN := FALSE);
ELSIF NOT xWrActive AND NOT xWrFinished THEN
    // sườn lên REQ: chụp khung request
    uiReqLen := INT_TO_UINT(LIMIT(0, iLen, UINT_TO_INT(GVL_IolConst.uiMAX_REC)));
    IF pData = 0 THEN
        uiReqLen := 0;
    END_IF
    FOR i := 0 TO UINT_TO_INT(uiReqLen) - 1 DO
        abReq[i] := pData[i];
    END_FOR
    xWrActive := TRUE;
END_IF

IF xWrActive THEN
    tonWr(IN := TRUE, PT := tDelayWr);
    IF tonWr.Q AND NOT xInjNoResponse THEN
        tonWr(IN := FALSE);
        xWrActive   := FALSE;
        xWrFinished := TRUE;
        udiWrCount  := udiWrCount + 1;
        IF xInjPnioErr OR iIndex <> UINT_TO_INT(GVL_IolConst.uiCAP_INDEX) THEN
            xWrFailed := TRUE;
            dwWrStat  := 16#DE80B000;          // invalid index
        ELSE
            xWrFailed := FALSE;
            dwWrStat  := 0;
            ProcessRequest();
        END_IF
    END_IF
END_IF

xBusy  := xWrActive;
xDone  := xWrFinished AND NOT xWrFailed;
xError := xWrFinished AND xWrFailed;
IF xError THEN
    dwStatus := dwWrStat;
ELSE
    dwStatus := 0;
END_IF
Write := xWrFinished;

METHOD Read : BOOL
VAR_INPUT
    xReq   : BOOL;
    dwId   : DWORD;
    iIndex : INT;
    iMLen  : INT;
    pData  : POINTER TO BYTE;
END_VAR
VAR_OUTPUT
    xValid   : BOOL;
    xBusy    : BOOL;
    xError   : BOOL;
    dwStatus : DWORD;
    iLen     : INT;
END_VAR
VAR
    i : INT;
    n : INT;
END_VAR

(*---IMPL---*)
IF NOT xInit THEN
    InitStore();
END_IF

IF NOT xReq THEN
    xRdActive   := FALSE;
    xRdFinished := FALSE;
    xRdFailed   := FALSE;
    tonRd(IN := FALSE);
ELSIF NOT xRdActive AND NOT xRdFinished THEN
    xRdActive := TRUE;
END_IF

IF xRdActive THEN
    tonRd(IN := TRUE, PT := tDelayRd);
    IF tonRd.Q AND NOT xInjNoResponse THEN
        tonRd(IN := FALSE);
        xRdActive   := FALSE;
        xRdFinished := TRUE;
        udiRdCount  := udiRdCount + 1;
        iRdLenOut   := 0;
        IF iIndex <> UINT_TO_INT(GVL_IolConst.uiCAP_INDEX) THEN
            xRdFailed := TRUE;
            dwRdStat  := 16#DE80B000;          // invalid index
        ELSIF usiBusyLeft > 0 OR NOT xRespReady THEN
            // master chưa xử lý xong ISDU (hoặc chưa có request) -> state conflict, client retry
            IF usiBusyLeft > 0 THEN
                usiBusyLeft := usiBusyLeft - 1;
            END_IF
            xRdFailed := TRUE;
            dwRdStat  := 16#DE80B500;
        ELSE
            n := MIN(UINT_TO_INT(uiRespLen), iMLen);
            IF pData = 0 THEN
                n := 0;
            END_IF
            FOR i := 0 TO n - 1 DO
                pData[i] := abResp[i];
            END_FOR
            iRdLenOut  := n;
            xRespReady := FALSE;               // phản hồi chỉ đọc được 1 lần
            xRdFailed  := FALSE;
            dwRdStat   := 0;
        END_IF
    END_IF
END_IF

xBusy  := xRdActive;
xValid := xRdFinished AND NOT xRdFailed;
xError := xRdFinished AND xRdFailed;
IF xError THEN
    dwStatus := dwRdStat;
ELSE
    dwStatus := 0;
END_IF
IF xValid THEN
    iLen := iRdLenOut;
ELSE
    iLen := 0;
END_IF
Read := xRdFinished;

(*---IMPL---*)
iStoreCount := 0;
// --- Nhận dạng chuẩn 16..24 ---
AddStr(16,  E_IolAccess.RO, 'ifm electronic gmbh');
AddStr(17,  E_IolAccess.RO, 'www.ifm.com');
AddStr(18,  E_IolAccess.RO, 'O5D150');
AddStr(19,  E_IolAccess.RO, 'O5D150');
AddStr(20,  E_IolAccess.RO, 'Laser distance sensor (SIM)');
AddStr(21,  E_IolAccess.RO, 'SIM0001');
AddStr(22,  E_IolAccess.RO, 'AB');
AddStr(23,  E_IolAccess.RO, 'SIM 1.0');
AddStr(24,  E_IolAccess.RW, '***');
// --- Tham số theo IODD (giá trị big-endian) ---
AddRaw(60,  E_IolAccess.RW, 4, 16#00640000);   // SP1 = 100 cm, SP2 = 0 (not used)
AddRaw(61,  E_IolAccess.RW, 4, 16#00010000);   // Logic = 0 NO, Mode = 1, Hyst = 0
AddRaw(64,  E_IolAccess.RO, 4, 16#000500C8);   // Limit min 5 cm, max 200 cm
AddRaw(69,  E_IolAccess.RO, 1, 75);            // Align %
AddRaw(74,  E_IolAccess.RW, 2, 0);             // dFO
AddRaw(76,  E_IolAccess.RW, 2, 0);             // dS
AddRaw(78,  E_IolAccess.RW, 2, 0);             // dr
AddRaw(80,  E_IolAccess.RW, 1, 1);             // Laser On
AddRaw(96,  E_IolAccess.RW, 1, 1);             // Display On
AddRaw(100, E_IolAccess.RW, 1, 1);             // KeyLock Unlocked
xInit := TRUE;

// Nạp bảng dữ liệu O5D150 mặc định (cũng dùng cho System Command 130 factory reset)
METHOD PRIVATE InitStore

// Thêm 1 index số (1, 2 hoặc 4 byte, big-endian) vào bảng giả lập
METHOD PRIVATE AddRaw
VAR_INPUT
    uiIndex : UINT;
    eAccess : E_IolAccess;
    uiLen   : UINT;          // 1, 2 hoặc 4
    dwVal   : DWORD;
END_VAR

(*---IMPL---*)
IF iStoreCount > 19 THEN
    RETURN;
END_IF
aStore[iStoreCount].uiIndex := uiIndex;
aStore[iStoreCount].eAccess := eAccess;
aStore[iStoreCount].uiLen   := uiLen;
CASE uiLen OF
    1: aStore[iStoreCount].abData[0] := DWORD_TO_BYTE(dwVal);
    2: F_IolSetU16BE(ADR(aStore[iStoreCount].abData), 0, DWORD_TO_UINT(dwVal));
ELSE
    aStore[iStoreCount].uiLen := 4;
    F_IolSetU32BE(ADR(aStore[iStoreCount].abData), 0, dwVal);
END_CASE
iStoreCount := iStoreCount + 1;

// Thêm 1 index chuỗi (StringT, không ký tự kết thúc) vào bảng giả lập
METHOD PRIVATE AddStr
VAR_INPUT
    uiIndex : UINT;
    eAccess : E_IolAccess;
    sVal    : STRING(63);
END_VAR
VAR
    pSrc : POINTER TO BYTE;
    n    : INT;
    i    : INT;
END_VAR

(*---IMPL---*)
IF iStoreCount > 19 THEN
    RETURN;
END_IF
pSrc := ADR(sVal);
n := LEN(sVal);
aStore[iStoreCount].uiIndex := uiIndex;
aStore[iStoreCount].eAccess := eAccess;
aStore[iStoreCount].uiLen   := INT_TO_UINT(n);
FOR i := 0 TO n - 1 DO
    aStore[iStoreCount].abData[i] := pSrc[i];
END_FOR
iStoreCount := iStoreCount + 1;

// Vị trí index trong bảng, -1 nếu không có
METHOD PRIVATE FindStore : INT
VAR_INPUT
    uiIndex : UINT;
END_VAR
VAR
    i : INT;
END_VAR

(*---IMPL---*)
FindStore := -1;
FOR i := 0 TO iStoreCount - 1 DO
    IF aStore[i].uiIndex = uiIndex THEN
        FindStore := i;
        RETURN;
    END_IF
END_FOR

// Vị trí byte của subindex trong record (theo IODD O5D150); FALSE = subindex không tồn tại
METHOD PRIVATE SubRange : BOOL
VAR_INPUT
    iStore  : INT;
    usiSub  : USINT;
END_VAR
VAR_OUTPUT
    uiOff : UINT;
    uiLen : UINT;
END_VAR

(*---IMPL---*)
SubRange := TRUE;
uiOff := 0;
uiLen := 0;
IF usiSub = 0 THEN
    uiLen := aStore[iStore].uiLen;
    RETURN;
END_IF
CASE aStore[iStore].uiIndex OF
    60:                                   // SP: sub1 SP1, sub2 SP2
        CASE usiSub OF
            1: uiOff := 0; uiLen := 2;
            2: uiOff := 2; uiLen := 2;
        ELSE
            SubRange := FALSE;
        END_CASE
    61:                                   // Config: sub1 Logic, sub2 Mode, sub3 Hyst
        CASE usiSub OF
            1: uiOff := 0; uiLen := 1;
            2: uiOff := 1; uiLen := 1;
            3: uiOff := 2; uiLen := 2;
        ELSE
            SubRange := FALSE;
        END_CASE
    64:                                   // Limit: sub1 min, sub2 max
        CASE usiSub OF
            1: uiOff := 0; uiLen := 2;
            2: uiOff := 2; uiLen := 2;
        ELSE
            SubRange := FALSE;
        END_CASE
ELSE
    SubRange := FALSE;
END_CASE

// Kiểm dải giá trị của cả record sau khi ghi (theo IODD); FALSE -> device trả 0x8030
METHOD PRIVATE CheckImage : BOOL
VAR_INPUT
    uiIndex : UINT;
    pImg    : POINTER TO BYTE;
END_VAR
VAR
    uiV1 : UINT;
    uiV2 : UINT;
END_VAR

(*---IMPL---*)
CheckImage := TRUE;
CASE uiIndex OF
    60:                                         // SP1 5..200 cm, SP2 = 0 (not used)
        uiV1 := F_IolGetU16BE(pImg, 0);
        uiV2 := F_IolGetU16BE(pImg, 2);
        CheckImage := (uiV1 >= 5) AND (uiV1 <= 200) AND (uiV2 = 0);
    61:                                         // Logic 0..1, Mode = 1, Hyst = 0
        CheckImage := (pImg[0] <= 1) AND (pImg[1] = 1) AND (F_IolGetU16BE(pImg, 2) = 0);
    74, 76, 78:                                 // dFO / dS / dr 0..2000
        CheckImage := F_IolGetU16BE(pImg, 0) <= 2000;
    80, 100:                                    // Laser, KeyLock 0..1
        CheckImage := pImg[0] <= 1;
    96:                                         // Display 0..2
        CheckImage := pImg[0] <= 2;
END_CASE

// Hoàn tất phản hồi OK: header đã echo trong abResp[0..7], dữ liệu đọc ở abResp[8..]
METHOD PRIVATE RespOk
VAR_INPUT
    uiDataLen : UINT;
END_VAR

(*---IMPL---*)
uiRespLen := GVL_IolConst.uiHDR_LEN + uiDataLen;
IF xInjBadFrame THEN
    abResp[0] := 0;
END_IF

// Phản hồi lỗi: Control = 0x80, byte 5..6 IOL_M_ErrorCode, byte 7..8 IOL_D_ErrorCode (layout giả định plan 4.2)
METHOD PRIVATE RespErr
VAR_INPUT
    uiMasterErr : UINT;
    uiDevErr    : UINT;
END_VAR

(*---IMPL---*)
abResp[4] := GVL_IolConst.usiCTRL_ERROR;
F_IolSetU16BE(ADR(abResp), 5, uiMasterErr);
F_IolSetU16BE(ADR(abResp), 7, uiDevErr);
uiRespLen := 9;
IF xInjBadFrame THEN
    abResp[0] := 0;
END_IF

// Xử lý 1 khung IOL_CALL đã nhận (abReq), tạo phản hồi trong abResp như AL1100 + O5D150
METHOD PRIVATE ProcessRequest
VAR
    usiPort   : USINT;
    bCtrl     : BYTE;
    uiIdx     : UINT;
    usiSub    : USINT;
    uiDataLen : UINT;
    iS        : INT;
    uiOff     : UINT;
    uiSubLen  : UINT;
    i         : INT;
    n         : UINT;
    awList    : ARRAY[0..5] OF WORD;   // event đang active để trả ở index 37
    abQual    : ARRAY[0..5] OF BYTE;
END_VAR

(*---IMPL---*)
xRespReady  := TRUE;
usiBusyLeft := usiInjBusyCount;
FOR i := 0 TO 7 DO                       // phản hồi echo header request
    abResp[i] := abReq[i];
END_FOR

// ---------- 1. Kiểm khung ----------
IF uiReqLen < GVL_IolConst.uiHDR_LEN
   OR abReq[0] <> GVL_IolConst.usiEXT_FUNC_NUM
   OR F_IolGetU16BE(ADR(abReq), 2) <> GVL_IolConst.uiFI_INDEX THEN
    RespErr(16#7001, 0);                 // wrong IOL_CALL
    RETURN;
END_IF
usiPort   := abReq[1];
bCtrl     := abReq[4];
uiIdx     := F_IolGetU16BE(ADR(abReq), 5);
usiSub    := abReq[7];
uiDataLen := uiReqLen - GVL_IolConst.uiHDR_LEN;

IF usiPort < 1 OR usiPort > 4 THEN
    RespErr(16#8001, 0);                 // port không hợp lệ
    RETURN;
END_IF
IF usiPort <> usiDevPort OR NOT xDevPresent THEN
    RespErr(16#8004, 0);                 // không liên lạc được device trên port
    RETURN;
END_IF
IF bCtrl <> GVL_IolConst.usiCTRL_READ AND bCtrl <> GVL_IolConst.usiCTRL_WRITE THEN
    RespErr(16#7001, 0);
    RETURN;
END_IF
IF uiInjDevErr <> 0 THEN
    RespErr(0, uiInjDevErr);
    RETURN;
END_IF

// ---------- 2. Index 37: Detailed Device Status (3 byte/entry: qualifier + code) ----------
IF uiIdx = GVL_O5D150_Def.uiIDX_EVT_LIST THEN
    IF bCtrl = GVL_IolConst.usiCTRL_WRITE THEN
        RespErr(0, GVL_IolConst.uiERR_ACCESS);
    ELSIF xIdx37NotSupported THEN
        RespErr(0, GVL_IolConst.uiERR_IDX_NA);
    ELSE
        awList[0] := SEL(xEvt1Active, 0, 16#8DFE);  abQual[0] := 16#D4;   // appear, notification, device, application
        awList[1] := SEL(xEvt2Active, 0, 16#8DFF);  abQual[1] := 16#D4;
        FOR i := 0 TO 3 DO
            awList[i + 2] := awInjEvent[i];
            abQual[i + 2] := 16#E4;                                        // appear, warning
        END_FOR
        n := 0;
        FOR i := 0 TO 5 DO
            IF awList[i] <> 0 THEN
                abResp[8 + n] := abQual[i];
                F_IolSetU16BE(ADR(abResp), 9 + n, WORD_TO_UINT(awList[i]));
                n := n + 3;
            END_IF
        END_FOR
        RespOk(n);
    END_IF
    RETURN;
END_IF

// ---------- 3. Index 2: System Command ----------
IF uiIdx = GVL_O5D150_Def.uiIDX_SYS_CMD THEN
    IF bCtrl = GVL_IolConst.usiCTRL_READ THEN
        RespErr(0, GVL_IolConst.uiERR_ACCESS);      // write only
    ELSIF uiDataLen > 1 THEN
        RespErr(0, 16#8033);
    ELSIF uiDataLen < 1 THEN
        RespErr(0, 16#8034);
    ELSE
        usiLastSysCmd := abReq[8];
        CASE usiLastSysCmd OF
            130: InitStore(); xEvt1Active := FALSE; xEvt2Active := FALSE; RespOk(0);
            240: xEvt1Active := TRUE;  RespOk(0);
            241: xEvt1Active := FALSE; RespOk(0);
            242: xEvt2Active := TRUE;  RespOk(0);
            243: xEvt2Active := FALSE; RespOk(0);
        ELSE
            RespErr(0, 16#8035);                    // lệnh không có trong IODD
        END_CASE
    END_IF
    RETURN;
END_IF

// ---------- 4. Bảng tham số ----------
iS := FindStore(uiIdx);
IF iS < 0 THEN
    RespErr(0, GVL_IolConst.uiERR_IDX_NA);
    RETURN;
END_IF
IF NOT SubRange(iStore := iS, usiSub := usiSub, uiOff => uiOff, uiLen => uiSubLen) THEN
    RespErr(0, GVL_IolConst.uiERR_SUBIDX_NA);
    RETURN;
END_IF

IF bCtrl = GVL_IolConst.usiCTRL_READ THEN
    IF aStore[iS].eAccess = E_IolAccess.WO THEN
        RespErr(0, GVL_IolConst.uiERR_ACCESS);
        RETURN;
    END_IF
    IF uiIdx = 69 THEN
        aStore[iS].abData[0] := usiSimAlign;
    END_IF
    FOR i := 0 TO UINT_TO_INT(uiSubLen) - 1 DO
        abResp[8 + i] := aStore[iS].abData[uiOff + INT_TO_UINT(i)];
    END_FOR
    RespOk(uiSubLen);
ELSE
    IF aStore[iS].eAccess = E_IolAccess.RO THEN
        RespErr(0, GVL_IolConst.uiERR_ACCESS);
    ELSIF uiDataLen > uiSubLen THEN
        RespErr(0, 16#8033);
    ELSIF uiDataLen < uiSubLen THEN
        RespErr(0, 16#8034);
    ELSE
        // ghép giá trị mới vào bản sao record rồi kiểm dải trước khi chấp nhận
        abTmp := aStore[iS].abData;
        FOR i := 0 TO UINT_TO_INT(uiSubLen) - 1 DO
            abTmp[uiOff + INT_TO_UINT(i)] := abReq[8 + i];
        END_FOR
        IF CheckImage(uiIdx, ADR(abTmp)) THEN
            aStore[iS].abData := abTmp;
            RespOk(0);
        ELSE
            RespErr(0, GVL_IolConst.uiERR_RANGE);
        END_IF
    END_IF
END_IF

