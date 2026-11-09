// Lớp cơ sở cho mọi device IO-Link: giải mã PQI, trình tự đọc/ghi tham số theo bảng IODD của lớp con,
// đọc Ident 16..24, kênh ISDU tự do cho lớp con. Lớp con override: ParamCount, GetParamDef, GetValPtr,
// OnParamDone, OnCustomDone và gọi SUPER^() trong thân.
FUNCTION_BLOCK FB_IolDevBase
VAR_INPUT
    refMaster          : REFERENCE TO FB_IolMaster;
    usiPort            : USINT;
    bPQI               : BYTE;                  // Port Qualifier từ GVL_IO
    xWriteEnable       : BOOL;                  // khoá ghi tham số / System Command (Maintenance)
    xAutoReadOnConnect : BOOL := TRUE;          // tự đọc Ident + ReadAll khi PD chuyển hợp lệ
    xResetErr          : BOOL;                  // sườn lên: xoá lỗi gần nhất
END_VAR
VAR_OUTPUT
    stDiag         : ST_IolPortDiag;
    xPdValid       : BOOL;                      // PQ AND DA
    xBusy          : BOOL;                      // đang chạy hoặc còn việc chờ
    xLastError     : BOOL;                      // lỗi gần nhất, giữ tới xResetErr
    eLastErrSrc    : E_IolErrSource;
    uiLastDevErr   : UINT;
    wsLastErr      : WSTRING(80);
    stIdent        : ST_IolIdent;
    udiJobCount    : UDINT;
    udiJobErrCount : UDINT;
END_VAR
VAR
    fbCall      : FB_IolCall;                   // instance riêng mỗi device
    eSeq        : E_IolDevSeq;
    eJob        : E_IolDevJob;
    iJobParam   : INT;
    uiJobIndex  : UINT;
    usiJobSub   : USINT;
    eJobService : E_IolService := E_IolService.READ;
    uiJobLen    : UINT;
    xCallExec   : BOOL;
    abBuf       : ARRAY[0..GVL_IolConst.uiMAX_DATA - 1] OF BYTE;   // dữ liệu ghi / nhận của việc đang chạy
    axPendRead  : ARRAY[0..GVL_IolConst.iMAX_PARAM - 1] OF BOOL;
    axPendWrite : ARRAY[0..GVL_IolConst.iMAX_PARAM - 1] OF BOOL;
    wPendIdent  : WORD;                         // bit n = cần đọc index 16 + n
    xPendCustom : BOOL;
    stCustom    : ST_IolRequest;
    rtPdValid   : R_TRIG;
    rtResetErr  : R_TRIG;
END_VAR

(*---IMPL---*)
// ---------- 1. Port Qualifier (bit theo GSDML AL1100) ----------
stDiag.bPQI := bPQI;
stDiag.xDI4 := bPQI.0;
stDiag.xDI2 := bPQI.1;
stDiag.xNP  := bPQI.2;
stDiag.xSV  := bPQI.3;
stDiag.xDA  := bPQI.4;
stDiag.xDC  := bPQI.5;
stDiag.xDE  := bPQI.6;
stDiag.xPQ  := bPQI.7;
xPdValid := stDiag.xPQ AND stDiag.xDA;

rtPdValid(CLK := xPdValid);
IF rtPdValid.Q AND xAutoReadOnConnect THEN
    RequestReadIdent();
    RequestReadAll();
END_IF

rtResetErr(CLK := xResetErr);
IF rtResetErr.Q THEN
    xLastError   := FALSE;
    eLastErrSrc  := E_IolErrSource.NONE;
    uiLastDevErr := 0;
    wsLastErr    := "";
END_IF

// ---------- 2. Port không có thiết bị: huỷ việc chờ ngay, không đợi timeout ----------
IF NOT stDiag.xDA AND eSeq = E_IolDevSeq.IDLE AND HasPending() THEN
    DropAll();
END_IF

// ---------- 3. Client IOL_CALL: gọi đúng 1 lần mỗi chu kỳ ----------
IF __ISVALIDREF(refMaster) THEN
    fbCall.refMaster REF= refMaster;
END_IF
IF eJobService = E_IolService.WRITE THEN
    fbCall(xExecute := xCallExec, usiPort := usiPort, eService := eJobService, uiIndex := uiJobIndex,
           usiSubindex := usiJobSub, pData := ADR(abBuf), uiDataLen := uiJobLen);
ELSE
    fbCall(xExecute := xCallExec, usiPort := usiPort, eService := eJobService, uiIndex := uiJobIndex,
           usiSubindex := usiJobSub, pData := ADR(abBuf), uiDataLen := GVL_IolConst.uiMAX_DATA);
END_IF

// ---------- 4. Trình tự việc ----------
CASE eSeq OF
    E_IolDevSeq.IDLE:
        xCallExec := FALSE;
        IF SelectJob() THEN
            xCallExec := TRUE;
            eSeq := E_IolDevSeq.RUN;
        END_IF

    E_IolDevSeq.RUN:
        IF fbCall.xDone OR fbCall.xError THEN
            xCallExec := FALSE;
            JobFinished(xErr := fbCall.xError);
            eSeq := E_IolDevSeq.RELEASE;
        END_IF

    E_IolDevSeq.RELEASE:
        // chờ FB_IolCall về IDLE để sườn Execute kế tiếp chắc chắn được nhận
        IF NOT fbCall.xDone AND NOT fbCall.xError AND NOT fbCall.xBusy THEN
            eJob := E_IolDevJob.NONE;
            eSeq := E_IolDevSeq.IDLE;
        END_IF
END_CASE

xBusy := (eSeq <> E_IolDevSeq.IDLE) OR HasPending();

(*---IMPL---*)
ParamCount := 0;

// Số tham số trong bảng IODD của device - lớp con override
METHOD ParamCount : INT

// Định nghĩa tham số thứ iParam - lớp con override
METHOD GetParamDef : ST_IolParamDef
VAR_INPUT
    iParam : INT;
END_VAR
VAR
    stEmpty : ST_IolParamDef;
END_VAR

(*---IMPL---*)
GetParamDef := stEmpty;

// Con trỏ tới giá trị runtime của tham số iParam (mảng nằm ở lớp con); 0 = không có
METHOD GetValPtr : POINTER TO ST_IolParamVal
VAR_INPUT
    iParam : INT;
END_VAR

(*---IMPL---*)
GetValPtr := 0;

// Hook sau khi đọc xong 1 tham số (lớp con tách record nhiều trường...)
METHOD OnParamDone
VAR_INPUT
    iParam : INT;
    xErr   : BOOL;
END_VAR

(*---IMPL---*)
;

// Hook khi việc ISDU tự do kết thúc; dữ liệu đọc nằm trong abBuf[0..uiLen-1].
// Trả TRUE để KHÔNG đẩy lỗi lên wsLastErr (lớp con tự xử lý, vd index không hỗ trợ).
METHOD OnCustomDone : BOOL
VAR_INPUT
    uiIndex  : UINT;
    eService : E_IolService;
    xErr     : BOOL;
    uiDevErr : UINT;
    uiLen    : UINT;
END_VAR

(*---IMPL---*)
OnCustomDone := FALSE;

// Đánh dấu đọc mọi tham số có xInReadAll và không phải write-only
METHOD RequestReadAll
VAR
    i     : INT;
    stDef : ST_IolParamDef;
END_VAR

(*---IMPL---*)
FOR i := 0 TO MIN(THIS^.ParamCount(), GVL_IolConst.iMAX_PARAM) - 1 DO
    stDef := THIS^.GetParamDef(i);
    IF stDef.xInReadAll AND stDef.eAccess <> E_IolAccess.WO THEN
        axPendRead[i] := TRUE;
    END_IF
END_FOR

(*---IMPL---*)
wPendIdent := 16#01FF;

// Đánh dấu đọc Ident index 16..24
METHOD RequestReadIdent

// Đánh dấu đọc 1 tham số; FALSE nếu iParam sai hoặc tham số write-only
METHOD RequestRead : BOOL
VAR_INPUT
    iParam : INT;
END_VAR
VAR
    stDef : ST_IolParamDef;
END_VAR

(*---IMPL---*)
RequestRead := FALSE;
IF iParam < 0 OR iParam >= MIN(THIS^.ParamCount(), GVL_IolConst.iMAX_PARAM) THEN
    RETURN;
END_IF
stDef := THIS^.GetParamDef(iParam);
IF stDef.eAccess = E_IolAccess.WO THEN
    RETURN;
END_IF
axPendRead[iParam] := TRUE;
RequestRead := TRUE;

// Yêu cầu ghi 1 tham số. Chặn trước khi gửi: khoá ghi (xWriteEnable), tham số read-only, ngoài dải IODD.
// Ghi xong tự đọc lại để xác nhận.
METHOD RequestWrite : BOOL
VAR_INPUT
    iParam  : INT;
    diValue : DINT;
END_VAR
VAR
    stDef : ST_IolParamDef;
    pVal  : POINTER TO ST_IolParamVal;
END_VAR

(*---IMPL---*)
RequestWrite := FALSE;
IF iParam < 0 OR iParam >= MIN(THIS^.ParamCount(), GVL_IolConst.iMAX_PARAM) THEN
    SetLocalErr(E_IolErrSource.PARAM);
    RETURN;
END_IF
stDef := THIS^.GetParamDef(iParam);
pVal  := THIS^.GetValPtr(iParam);
IF pVal = 0 OR stDef.eAccess = E_IolAccess.RO THEN
    SetLocalErr(E_IolErrSource.PARAM);
    RETURN;
END_IF
IF NOT xWriteEnable THEN
    SetLocalErr(E_IolErrSource.WRITE_LOCKED);
    RETURN;
END_IF
IF diValue < stDef.diMin OR diValue > stDef.diMax THEN
    pVal^.uiErr := 16#FF00 OR INT_TO_UINT(E_IolErrSource.RANGE);
    SetLocalErr(E_IolErrSource.RANGE);
    RETURN;
END_IF
pVal^.diSet  := diValue;
pVal^.xDirty := TRUE;
axPendWrite[iParam] := TRUE;
RequestWrite := TRUE;

// ISDU tự do (System Command, event list...). 1 việc chờ tại 1 thời điểm; FALSE nếu đang có việc chờ,
// ghi bị khoá hoặc độ dài sai. Kết quả báo qua OnCustomDone.
METHOD RequestCustom : BOOL
VAR_INPUT
    eService    : E_IolService;
    uiIndex     : UINT;
    usiSubindex : USINT;
    pData       : POINTER TO BYTE;     // chỉ dùng khi WRITE
    uiLen       : UINT;                // số byte ghi (READ bỏ qua)
END_VAR
VAR
    i : INT;
END_VAR

(*---IMPL---*)
RequestCustom := FALSE;
IF xPendCustom THEN
    RETURN;
END_IF
IF eService = E_IolService.WRITE THEN
    IF NOT xWriteEnable THEN
        SetLocalErr(E_IolErrSource.WRITE_LOCKED);
        RETURN;
    END_IF
    IF pData = 0 OR uiLen = 0 OR uiLen > GVL_IolConst.uiMAX_DATA THEN
        SetLocalErr(E_IolErrSource.PARAM);
        RETURN;
    END_IF
    FOR i := 0 TO UINT_TO_INT(uiLen) - 1 DO
        stCustom.abData[i] := pData[i];
    END_FOR
    stCustom.uiLen := uiLen;
ELSE
    stCustom.uiLen := 0;
END_IF
stCustom.usiPort     := usiPort;
stCustom.eService    := eService;
stCustom.uiIndex     := uiIndex;
stCustom.usiSubindex := usiSubindex;
xPendCustom := TRUE;
RequestCustom := TRUE;

// Ghi lỗi phát sinh trong PLC (không qua ISDU) vào lỗi gần nhất
METHOD PROTECTED SetLocalErr
VAR_INPUT
    eSrc : E_IolErrSource;
END_VAR

(*---IMPL---*)
xLastError   := TRUE;
eLastErrSrc  := eSrc;
uiLastDevErr := 0;
wsLastErr    := F_IolErrText(eSrc, 0, 0, 0);

(*---IMPL---*)
xLastError   := TRUE;
eLastErrSrc  := fbCall.eErrSource;
uiLastDevErr := fbCall.uiIolDevErr;
wsLastErr    := fbCall.wsErrText;

// Chép lỗi của lần gọi ISDU vừa xong vào lỗi gần nhất
METHOD PROTECTED ReportErr

(*---IMPL---*)
IF fbCall.uiIolDevErr <> 0 THEN
    ErrCode := fbCall.uiIolDevErr;
ELSE
    ErrCode := 16#FF00 OR INT_TO_UINT(fbCall.eErrSource);
END_IF

// Mã lỗi lưu vào ST_IolParamVal.uiErr: lỗi device 0x80xx, còn lại 0xFF00 + E_IolErrSource
METHOD PROTECTED ErrCode : UINT

// Còn việc ISDU nào đang chờ không
METHOD PROTECTED HasPending : BOOL
VAR
    i : INT;
END_VAR

(*---IMPL---*)
HasPending := xPendCustom OR (wPendIdent <> 0);
FOR i := 0 TO GVL_IolConst.iMAX_PARAM - 1 DO
    IF axPendRead[i] OR axPendWrite[i] THEN
        HasPending := TRUE;
        RETURN;
    END_IF
END_FOR

// Huỷ mọi việc chờ khi port không có thiết bị, báo NO_DEVICE thay vì để từng request timeout
METHOD PROTECTED DropAll
VAR
    i : INT;
END_VAR

(*---IMPL---*)
FOR i := 0 TO GVL_IolConst.iMAX_PARAM - 1 DO
    axPendRead[i]  := FALSE;
    axPendWrite[i] := FALSE;
END_FOR
wPendIdent := 0;
IF xPendCustom THEN
    xPendCustom := FALSE;
    THIS^.OnCustomDone(uiIndex := stCustom.uiIndex, eService := stCustom.eService, xErr := TRUE, uiDevErr := 0, uiLen := 0);
END_IF
SetLocalErr(E_IolErrSource.NO_DEVICE);

// Chọn việc tiếp theo theo ưu tiên: tự do (System Command / event) > ghi > đọc tham số > Ident
METHOD PROTECTED SelectJob : BOOL
VAR
    i     : INT;
    iN    : INT;
    stDef : ST_IolParamDef;
END_VAR

(*---IMPL---*)
SelectJob := FALSE;
IF NOT stDiag.xDA THEN
    RETURN;
END_IF
iN := MIN(THIS^.ParamCount(), GVL_IolConst.iMAX_PARAM);

// --- 1. ISDU tự do ---
IF xPendCustom THEN
    xPendCustom := FALSE;
    eJob        := E_IolDevJob.CUSTOM;
    iJobParam   := -1;
    uiJobIndex  := stCustom.uiIndex;
    usiJobSub   := stCustom.usiSubindex;
    eJobService := stCustom.eService;
    uiJobLen    := stCustom.uiLen;
    FOR i := 0 TO UINT_TO_INT(stCustom.uiLen) - 1 DO
        abBuf[i] := stCustom.abData[i];
    END_FOR
    SelectJob := TRUE;
    RETURN;
END_IF

// --- 2. Ghi tham số ---
FOR i := 0 TO iN - 1 DO
    IF axPendWrite[i] THEN
        axPendWrite[i] := FALSE;
        IF PrepareWrite(i) THEN
            eJob := E_IolDevJob.PARAM_WR;
            SelectJob := TRUE;
            RETURN;
        END_IF
    END_IF
END_FOR

// --- 3. Đọc tham số ---
FOR i := 0 TO iN - 1 DO
    IF axPendRead[i] THEN
        axPendRead[i] := FALSE;
        stDef := THIS^.GetParamDef(i);
        eJob        := E_IolDevJob.PARAM_RD;
        iJobParam   := i;
        uiJobIndex  := stDef.uiIndex;
        usiJobSub   := stDef.usiSubindex;
        eJobService := E_IolService.READ;
        uiJobLen    := 0;
        SelectJob := TRUE;
        RETURN;
    END_IF
END_FOR

// --- 4. Ident 16..24 ---
IF wPendIdent <> 0 THEN
    FOR i := 0 TO 8 DO
        IF (SHR(wPendIdent, i) AND WORD#1) <> 0 THEN
            wPendIdent  := wPendIdent AND NOT SHL(WORD#1, i);
            eJob        := E_IolDevJob.IDENT;
            iJobParam   := -1;
            uiJobIndex  := 16 + INT_TO_UINT(i);
            usiJobSub   := 0;
            eJobService := E_IolService.READ;
            uiJobLen    := 0;
            SelectJob := TRUE;
            RETURN;
        END_IF
    END_FOR
    wPendIdent := 0;
END_IF

// Mã hoá diSet của tham số iParam thành byte big-endian trong abBuf; FALSE nếu kiểu không hỗ trợ ghi qua bảng
METHOD PROTECTED PrepareWrite : BOOL
VAR_INPUT
    iParam : INT;
END_VAR
VAR
    stDef : ST_IolParamDef;
    pVal  : POINTER TO ST_IolParamVal;
END_VAR

(*---IMPL---*)
PrepareWrite := FALSE;
stDef := THIS^.GetParamDef(iParam);
pVal  := THIS^.GetValPtr(iParam);
IF pVal = 0 THEN
    RETURN;
END_IF
iJobParam   := iParam;
uiJobIndex  := stDef.uiIndex;
usiJobSub   := stDef.usiSubindex;
eJobService := E_IolService.WRITE;
CASE stDef.eType OF
    E_IolDataType.U8, E_IolDataType.I8:
        abBuf[0] := DINT_TO_BYTE(pVal^.diSet);
        uiJobLen := 1;
    E_IolDataType.U16, E_IolDataType.I16:
        F_IolSetU16BE(ADR(abBuf), 0, DINT_TO_UINT(pVal^.diSet));
        uiJobLen := 2;
    E_IolDataType.U32, E_IolDataType.I32:
        F_IolSetU32BE(ADR(abBuf), 0, DINT_TO_DWORD(pVal^.diSet));
        uiJobLen := 4;
ELSE
    pVal^.xDirty := FALSE;
    RETURN;
END_CASE
PrepareWrite := TRUE;

// Giải mã abBuf (big-endian) thành diRaw của tham số iParam
METHOD PROTECTED DecodeParam
VAR_INPUT
    iParam : INT;
    uiLen  : UINT;
END_VAR
VAR
    stDef  : ST_IolParamDef;
    pVal   : POINTER TO ST_IolParamVal;
    uiNeed : UINT;
END_VAR

(*---IMPL---*)
stDef := THIS^.GetParamDef(iParam);
pVal  := THIS^.GetValPtr(iParam);
IF pVal = 0 THEN
    RETURN;
END_IF
CASE stDef.eType OF
    E_IolDataType.U8, E_IolDataType.I8:   uiNeed := 1;
    E_IolDataType.U16, E_IolDataType.I16: uiNeed := 2;
ELSE
    uiNeed := 4;
END_CASE
IF uiLen < uiNeed THEN
    pVal^.xValid := FALSE;
    pVal^.uiErr  := 16#FF00 OR INT_TO_UINT(E_IolErrSource.FRAME);
    RETURN;
END_IF
CASE stDef.eType OF
    E_IolDataType.U8:  pVal^.diRaw := BYTE_TO_DINT(abBuf[0]);
    E_IolDataType.I8:  pVal^.diRaw := SINT_TO_DINT(BYTE_TO_SINT(abBuf[0]));
    E_IolDataType.U16: pVal^.diRaw := UINT_TO_DINT(F_IolGetU16BE(ADR(abBuf), 0));
    E_IolDataType.I16: pVal^.diRaw := INT_TO_DINT(UINT_TO_INT(F_IolGetU16BE(ADR(abBuf), 0)));
ELSE
    pVal^.diRaw := DWORD_TO_DINT(F_IolGetU32BE(ADR(abBuf), 0));   // U32/I32/OCTET 4 byte đầu
END_CASE
pVal^.xValid := TRUE;
pVal^.uiErr  := 0;

// Lưu chuỗi Ident vừa đọc (abBuf) vào stIdent
METHOD PROTECTED StoreIdent
VAR_INPUT
    uiIndex : UINT;
    uiLen   : UINT;
END_VAR
VAR
    sVal : STRING(64);
END_VAR

(*---IMPL---*)
sVal := F_IolBytesToStr(ADR(abBuf), uiLen);
CASE uiIndex OF
    16: stIdent.sVendorName  := sVal;
    17: stIdent.sVendorText  := sVal;
    18: stIdent.sProductName := sVal;
    19: stIdent.sProductId   := sVal;
    20: stIdent.sProductText := sVal;
    21: stIdent.sSerialNo    := sVal;
    22: stIdent.sHwRev       := sVal;
    23: stIdent.sFwRev       := sVal;
    24: stIdent.sAppTag      := sVal;
END_CASE

// Xử lý kết quả của việc vừa xong
METHOD PROTECTED JobFinished
VAR_INPUT
    xErr : BOOL;
END_VAR
VAR
    pVal : POINTER TO ST_IolParamVal;
END_VAR

(*---IMPL---*)
udiJobCount := udiJobCount + 1;
IF xErr THEN
    udiJobErrCount := udiJobErrCount + 1;
END_IF

CASE eJob OF
    E_IolDevJob.PARAM_RD:
        pVal := THIS^.GetValPtr(iJobParam);
        IF pVal <> 0 THEN
            IF xErr THEN
                pVal^.xValid := FALSE;
                pVal^.uiErr  := ErrCode();
            ELSE
                DecodeParam(iJobParam, fbCall.uiLenRead);
            END_IF
        END_IF
        IF xErr THEN
            ReportErr();
        END_IF
        THIS^.OnParamDone(iParam := iJobParam, xErr := xErr);

    E_IolDevJob.PARAM_WR:
        pVal := THIS^.GetValPtr(iJobParam);
        IF pVal <> 0 THEN
            pVal^.xDirty := FALSE;
            IF xErr THEN
                pVal^.uiErr := ErrCode();
            ELSE
                pVal^.uiErr := 0;
                axPendRead[iJobParam] := TRUE;     // đọc lại để xác nhận giá trị device đã nhận
            END_IF
        END_IF
        IF xErr THEN
            ReportErr();
        END_IF

    E_IolDevJob.IDENT:
        // index Ident là tuỳ chọn theo device: lỗi thì bỏ qua, giữ chuỗi rỗng
        IF NOT xErr THEN
            StoreIdent(uiJobIndex, fbCall.uiLenRead);
        END_IF

    E_IolDevJob.CUSTOM:
        IF NOT THIS^.OnCustomDone(uiIndex := uiJobIndex, eService := eJobService, xErr := xErr,
                                  uiDevErr := fbCall.uiIolDevErr, uiLen := fbCall.uiLenRead) AND xErr THEN
            ReportErr();
        END_IF
END_CASE

