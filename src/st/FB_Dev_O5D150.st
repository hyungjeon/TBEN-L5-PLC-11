// Cảm biến khoảng cách laser ifm O5D150 (IODD vendor 310 / device 372, IO-Link 1.1, PDin 16 bit, không PDout).
// 1) Cyclic: giải mã PDin + PQI.  2) Event: Test Event qua System Command, đọc danh sách event index 37.
// 3) Acyclic: SP1, Logic, Limit, Align, Laser, Display... theo bảng GVL_O5D150_Def.aParamDef.
FUNCTION_BLOCK FB_Dev_O5D150 EXTENDS FB_IolDevBase
VAR_INPUT
    abPdIn           : ARRAY[0..1] OF BYTE;    // PDin từ GVL_IO, big-endian
    xAlignMode       : BOOL;                   // TRUE: đọc Align (69) mỗi tAlignPoll
    // --- Lệnh (sườn lên) ---
    xCmdReadAll      : BOOL;
    xCmdReadIdent    : BOOL;
    xCmdWriteSP1     : BOOL;
    xCmdWriteLogic   : BOOL;
    xCmdWriteLaser   : BOOL;
    xCmdWriteDisplay : BOOL;
    xCmdTestEvt1On   : BOOL;
    xCmdTestEvt1Off  : BOOL;
    xCmdTestEvt2On   : BOOL;
    xCmdTestEvt2Off  : BOOL;
    xCmdReadEvents   : BOOL;
    // --- Giá trị đặt ---
    uiSetSP1         : UINT;                   // cm 5..200
    usiSetLogic      : USINT;                  // 0 NO / 1 NC
    usiSetLaser      : USINT;                  // 0 Off / 1 On
    usiSetDisplay    : USINT;                  // 0 Off / 1 On / 2 Rotated
    tAlignPoll       : TIME := T#500MS;
    tEvtPoll         : TIME := T#5S;           // chu kỳ đọc index 37 khi PD hợp lệ
END_VAR
VAR_OUTPUT
    stPd                 : ST_O5D150_PdIn;
    aVal                 : ARRAY[0..GVL_O5D150_Def.iPARAM_COUNT - 1] OF ST_IolParamVal;   // theo E_O5D150_Param
    uiLimitMin_cm        : UINT;
    uiLimitMax_cm        : UINT;
    axEvtActive          : ARRAY[0..GVL_O5D150_Def.iEVT_COUNT - 1] OF BOOL;   // theo GVL_O5D150_Def.aEvtDef
    xEvtErrorActive      : BOOL;               // có event loại ERROR đang active
    uiEvtCount           : UINT;               // số event đang active (kể cả mã lạ)
    wUnknownEvt          : WORD;               // mã event không có trong bảng (gần nhất)
    xEvtListValid        : BOOL;               // danh sách event đọc được lần gần nhất
    xEvtListNotSupported : BOOL;               // device trả 0x8011 cho index 37 -> ngừng đọc chu kỳ
END_VAR
VAR
    rtReadAll    : R_TRIG;
    rtReadIdent  : R_TRIG;
    rtWrSP1      : R_TRIG;
    rtWrLogic    : R_TRIG;
    rtWrLaser    : R_TRIG;
    rtWrDisplay  : R_TRIG;
    rtEvt1On     : R_TRIG;
    rtEvt1Off    : R_TRIG;
    rtEvt2On     : R_TRIG;
    rtEvt2Off    : R_TRIG;
    rtReadEvt    : R_TRIG;
    tonAlign     : TON;
    tonEvt       : TON;
    usiPendSysCmd: USINT;                      // System Command chờ gửi, 0 = không
    xPendEvtRead : BOOL;
    abCmd        : ARRAY[0..0] OF BYTE;
END_VAR

(*---IMPL---*)
// Nền: PQI, trình tự ISDU, Ident (FB_IolDevBase)
SUPER^();

// ---------- 1. Process data cyclic ----------
DecodePdIn();

// ---------- 2. Lệnh tham số (ghi bị chặn trong RequestWrite nếu chưa bật Maintenance / ngoài dải) ----------
rtReadAll(CLK := xCmdReadAll);
IF rtReadAll.Q THEN
    RequestReadAll();
END_IF
rtReadIdent(CLK := xCmdReadIdent);
IF rtReadIdent.Q THEN
    RequestReadIdent();
END_IF
rtWrSP1(CLK := xCmdWriteSP1);
IF rtWrSP1.Q THEN
    RequestWrite(iParam := E_O5D150_Param.SP1, diValue := UINT_TO_DINT(uiSetSP1));
END_IF
rtWrLogic(CLK := xCmdWriteLogic);
IF rtWrLogic.Q THEN
    RequestWrite(iParam := E_O5D150_Param.CFG_LOGIC, diValue := USINT_TO_DINT(usiSetLogic));
END_IF
rtWrLaser(CLK := xCmdWriteLaser);
IF rtWrLaser.Q THEN
    RequestWrite(iParam := E_O5D150_Param.LASER, diValue := USINT_TO_DINT(usiSetLaser));
END_IF
rtWrDisplay(CLK := xCmdWriteDisplay);
IF rtWrDisplay.Q THEN
    RequestWrite(iParam := E_O5D150_Param.DISPLAY, diValue := USINT_TO_DINT(usiSetDisplay));
END_IF

// ---------- 3. Align: đọc chu kỳ chậm chỉ khi đang căn chỉnh, tránh chiếm kênh ISDU ----------
tonAlign(IN := xAlignMode AND xPdValid AND NOT tonAlign.Q, PT := tAlignPoll);
IF tonAlign.Q THEN
    RequestRead(E_O5D150_Param.ALIGN);
END_IF

// ---------- 4. Test Event qua System Command (index 2) ----------
rtEvt1On(CLK := xCmdTestEvt1On);
IF rtEvt1On.Q THEN
    QueueSysCmd(GVL_O5D150_Def.usiSC_TEST_EVT1_ON);
END_IF
rtEvt1Off(CLK := xCmdTestEvt1Off);
IF rtEvt1Off.Q THEN
    QueueSysCmd(GVL_O5D150_Def.usiSC_TEST_EVT1_OFF);
END_IF
rtEvt2On(CLK := xCmdTestEvt2On);
IF rtEvt2On.Q THEN
    QueueSysCmd(GVL_O5D150_Def.usiSC_TEST_EVT2_ON);
END_IF
rtEvt2Off(CLK := xCmdTestEvt2Off);
IF rtEvt2Off.Q THEN
    QueueSysCmd(GVL_O5D150_Def.usiSC_TEST_EVT2_OFF);
END_IF
IF usiPendSysCmd <> 0 AND NOT xPendCustom THEN
    abCmd[0] := usiPendSysCmd;
    IF RequestCustom(eService := E_IolService.WRITE, uiIndex := GVL_O5D150_Def.uiIDX_SYS_CMD,
                     usiSubindex := 0, pData := ADR(abCmd), uiLen := 1) THEN
        usiPendSysCmd := 0;
    ELSIF NOT xWriteEnable THEN
        usiPendSysCmd := 0;                     // Maintenance bị tắt giữa chừng: bỏ lệnh
    END_IF
END_IF

// ---------- 5. Danh sách event (index 37). Kênh chính thức là PROFINET diagnosis/alarm của AL1100 (TODO) ----------
IF rtPdValid.Q THEN
    xEvtListNotSupported := FALSE;              // device mới cắm vào: thử lại
END_IF
rtReadEvt(CLK := xCmdReadEvents);
IF rtReadEvt.Q THEN
    xEvtListNotSupported := FALSE;
    xPendEvtRead := TRUE;
END_IF
tonEvt(IN := xPdValid AND NOT xEvtListNotSupported AND NOT tonEvt.Q, PT := tEvtPoll);
IF tonEvt.Q THEN
    xPendEvtRead := TRUE;
END_IF
IF xPendEvtRead AND NOT xPendCustom AND usiPendSysCmd = 0 THEN
    IF RequestCustom(eService := E_IolService.READ, uiIndex := GVL_O5D150_Def.uiIDX_EVT_LIST,
                     usiSubindex := 0, pData := 0, uiLen := 0) THEN
        xPendEvtRead := FALSE;
    END_IF
END_IF

// PDin 16 bit big-endian: Distance 12 bit từ bit 4 [cm], OUT1 bit 0 (layout trong GVL_O5D150_Def.stPdLayout)
METHOD PROTECTED DecodePdIn
VAR
    wRaw   : WORD;
    uiDist : UINT;
END_VAR

(*---IMPL---*)
wRaw := SHL(BYTE_TO_WORD(abPdIn[0]), 8) OR BYTE_TO_WORD(abPdIn[1]);
stPd.wRaw     := wRaw;
stPd.xPdValid := xPdValid;
IF xPdValid THEN
    uiDist := WORD_TO_UINT(SHR(wRaw, GVL_O5D150_Def.stPdLayout.usiDistBitOffset) AND GVL_O5D150_Def.stPdLayout.wDistMask);
    stPd.uiDistance_cm := uiDist;
    stPd.rDistance_m   := UINT_TO_REAL(uiDist) * GVL_O5D150_Def.stPdLayout.rGradient;
    stPd.xOut1         := (SHR(wRaw, GVL_O5D150_Def.stPdLayout.usiOut1Bit) AND WORD#1) <> 0;
    stPd.xOutOfRange   := uiDist < GVL_O5D150_Def.stPdLayout.uiDistMin OR uiDist > GVL_O5D150_Def.stPdLayout.uiDistMax;
ELSE
    // PD không hợp lệ: khoảng cách giữ giá trị cũ để HMI không nhảy về 0, OUT1 về FALSE (fail-safe)
    stPd.xOut1 := FALSE;
END_IF

// Xếp 1 System Command chờ gửi; bị khoá khi chưa bật Maintenance
METHOD PROTECTED QueueSysCmd
VAR_INPUT
    usiCmd : USINT;
END_VAR

(*---IMPL---*)
IF NOT xWriteEnable THEN
    SetLocalErr(E_IolErrSource.WRITE_LOCKED);
ELSE
    usiPendSysCmd := usiCmd;
END_IF

// Giải mã Detailed Device Status (index 37): mỗi entry 3 byte = EventQualifier + EventCode (big-endian),
// entry 0/0 = trống. Đánh dấu cờ theo bảng GVL_O5D150_Def.aEvtDef.
METHOD PROTECTED DecodeEvents
VAR_INPUT
    uiLen : UINT;
END_VAR
VAR
    k      : INT;
    j      : INT;
    wCode  : WORD;
    xFound : BOOL;
END_VAR

(*---IMPL---*)
FOR j := 0 TO GVL_O5D150_Def.iEVT_COUNT - 1 DO
    axEvtActive[j] := FALSE;
END_FOR
uiEvtCount      := 0;
xEvtErrorActive := FALSE;

FOR k := 0 TO UINT_TO_INT(uiLen / 3) - 1 DO
    wCode := UINT_TO_WORD(F_IolGetU16BE(ADR(abBuf), INT_TO_UINT(k * 3 + 1)));
    IF abBuf[k * 3] <> 0 OR wCode <> 0 THEN
        uiEvtCount := uiEvtCount + 1;
        xFound := FALSE;
        FOR j := 0 TO GVL_O5D150_Def.iEVT_COUNT - 1 DO
            IF GVL_O5D150_Def.aEvtDef[j].wCode = wCode THEN
                axEvtActive[j] := TRUE;
                xFound := TRUE;
                IF GVL_O5D150_Def.aEvtDef[j].eType = E_IolEvtType.ERROR THEN
                    xEvtErrorActive := TRUE;
                END_IF
            END_IF
        END_FOR
        IF NOT xFound THEN
            wUnknownEvt := wCode;
        END_IF
    END_IF
END_FOR
xEvtListValid := TRUE;

(*---IMPL---*)
ParamCount := GVL_O5D150_Def.iPARAM_COUNT;

METHOD ParamCount : INT

METHOD GetParamDef : ST_IolParamDef
VAR_INPUT
    iParam : INT;
END_VAR
VAR
    stEmpty : ST_IolParamDef;
END_VAR

(*---IMPL---*)
IF iParam >= 0 AND iParam < GVL_O5D150_Def.iPARAM_COUNT THEN
    GetParamDef := GVL_O5D150_Def.aParamDef[iParam];
ELSE
    GetParamDef := stEmpty;
END_IF

METHOD GetValPtr : POINTER TO ST_IolParamVal
VAR_INPUT
    iParam : INT;
END_VAR

(*---IMPL---*)
IF iParam >= 0 AND iParam < GVL_O5D150_Def.iPARAM_COUNT THEN
    GetValPtr := ADR(aVal[iParam]);
ELSE
    GetValPtr := 0;
END_IF

// Limit (index 64) là record 4 byte: min UINT16 | max UINT16 -> tách ra
METHOD OnParamDone
VAR_INPUT
    iParam : INT;
    xErr   : BOOL;
END_VAR
VAR
    dwRaw : DWORD;
END_VAR

(*---IMPL---*)
IF iParam = E_O5D150_Param.LIMITS AND NOT xErr THEN
    dwRaw := DINT_TO_DWORD(aVal[E_O5D150_Param.LIMITS].diRaw);
    uiLimitMin_cm := DWORD_TO_UINT(SHR(dwRaw, 16));
    uiLimitMax_cm := DWORD_TO_UINT(dwRaw AND 16#FFFF);
END_IF

// Kết quả ISDU tự do: index 37 (event list) và index 2 (System Command)
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
IF uiIndex = GVL_O5D150_Def.uiIDX_EVT_LIST AND eService = E_IolService.READ THEN
    IF xErr THEN
        xEvtListValid := FALSE;
        IF uiDevErr = GVL_IolConst.uiERR_IDX_NA THEN
            // IODD không khai báo index 37: ghi nhận 1 lần, ngừng đọc chu kỳ, không đẩy lỗi lên HMI
            xEvtListNotSupported := TRUE;
            OnCustomDone := TRUE;
        END_IF
    ELSE
        DecodeEvents(uiLen);
    END_IF
ELSIF uiIndex = GVL_O5D150_Def.uiIDX_SYS_CMD AND NOT xErr THEN
    xPendEvtRead := TRUE;          // cập nhật danh sách event ngay sau Test Event
END_IF

