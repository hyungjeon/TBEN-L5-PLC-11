// Giao tiếp HMI <-> FB_Dev_O5D150 (lệnh: HMI đặt TRUE, PRG_IOLink tự xoá)
TYPE ST_HMI_O5D150 :
STRUCT
    // --- Lệnh ---
    xCmdReadAll      : BOOL;
    xCmdReadIdent    : BOOL;
    xCmdWriteSP1     : BOOL;          // ghi uiSetSP1 (cần xMaintEnable)
    xCmdWriteLogic   : BOOL;
    xCmdWriteLaser   : BOOL;
    xCmdWriteDisplay : BOOL;
    xCmdTestEvt1On   : BOOL;          // System Command 240 (cần xMaintEnable)
    xCmdTestEvt1Off  : BOOL;          // 241
    xCmdTestEvt2On   : BOOL;          // 242
    xCmdTestEvt2Off  : BOOL;          // 243
    xCmdReadEvents   : BOOL;          // đọc index 37 ngay (thử lại cả khi đã báo không hỗ trợ)
    xCmdResetErr     : BOOL;
    xAlignMode       : BOOL;          // giữ TRUE: đọc Align (69) chu kỳ chậm

    // --- Giá trị đặt ---
    uiSetSP1         : UINT := 100;   // cm, 5..200
    usiSetLogic      : USINT;         // 0 NO, 1 NC
    usiSetLaser      : USINT := 1;    // 0 Off, 1 On
    usiSetDisplay    : USINT := 1;    // 0 Off, 1 On, 2 Rotated

    // --- Process data ---
    uiDistance_cm    : UINT;
    rDistance_m      : REAL;
    xOut1            : BOOL;
    xPdValid         : BOOL;
    xOutOfRange      : BOOL;
    xPQ              : BOOL;
    xDA              : BOOL;
    xDE              : BOOL;

    // --- Tham số đọc về ---
    uiSP1            : UINT;
    usiLogic         : USINT;
    uiLimitMin_cm    : UINT;
    uiLimitMax_cm    : UINT;
    usiAlign         : USINT;         // %
    usiLaser         : USINT;
    usiDisplay       : USINT;
    xParamValid      : BOOL;          // SP1 đọc được lần gần nhất

    // --- Nhận dạng ---
    sVendor          : STRING(64);
    sProduct         : STRING(64);
    sSerial          : STRING(64);
    sFwRev           : STRING(64);

    // --- Event ---
    axEvtActive      : ARRAY[0..GVL_O5D150_Def.iEVT_COUNT - 1] OF BOOL;   // theo GVL_O5D150_Def.aEvtDef
    uiEvtCount       : UINT;
    wUnknownEvt      : WORD;
    xEvtListNotSupported : BOOL;

    // --- Trạng thái / lỗi ---
    xBusy            : BOOL;
    xError           : BOOL;          // lỗi gần nhất (giữ tới xCmdResetErr)
    uiDevErr         : UINT;
    wsErrText        : WSTRING(80);
    xWriteLocked     : BOOL;          // = NOT xMaintEnable
END_STRUCT
END_TYPE

