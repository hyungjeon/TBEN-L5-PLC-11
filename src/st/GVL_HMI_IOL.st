{attribute 'qualified_only'}
// Giao tiếp HMI cho IO-Link (tách khỏi GVL_HMI của trình tự đèn DXP)
VAR_GLOBAL
    xMaintEnable    : BOOL;                 // cho phép ghi tham số / System Command (khoá mặc định)
    xCmdResetMaster : BOOL;                 // xoá hàng đợi / thoát STUCK (chỉ khi xMaintEnable)
    stO5D150        : ST_HMI_O5D150;        // O5D150 port 1

    // --- Trạng thái master AL1100 ---
    eMasterState    : E_IolCallState;
    udiCallCount    : UDINT;
    udiErrCount     : UDINT;
    xSimMode        : BOOL;                 // bản sao GVL_IolSys.xSimMode để hiển thị

    // --- Alarm (bit) ---
    xAlmP1_NoDevice   : BOOL;               // PQI.DA = 0 > 2 s
    xAlmP1_PdInvalid  : BOOL;               // DA = 1 nhưng PQ = 0 > 1 s
    xAlmP1_DevErr     : BOOL;               // PQI.DE
    xAlmP1_EvtError   : BOOL;               // có event loại ERROR đang active
    xAlmIolCallErr    : BOOL;               // lần gọi ISDU gần nhất lỗi
    xAlmMasterStuck   : BOOL;               // master kẹt, cần xCmdResetMaster
    xAlarmAny         : BOOL;               // OR các alarm mức Lỗi
    xWarningAny       : BOOL;               // OR các cảnh báo
END_VAR

