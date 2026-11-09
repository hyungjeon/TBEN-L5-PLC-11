{attribute 'qualified_only'}
// Instance master + transport IO-Link (gọi trong PRG_IOLink / MainTask)
VAR_GLOBAL
    xSimMode  : BOOL := TRUE;              // TRUE = dùng mock (Simulation). Đặt FALSE sau khi có PROFINET thật.
    fbMockAL1 : FB_MockRecordAccess;       // giả lập AL1100 + O5D150
    fbPnAL1   : FB_PnRecordAccess;         // transport PROFINET thật (hiện là khung)
    fbAL1     : FB_IolMaster;              // master AL1100: khoá + hàng đợi IOL_CALL
END_VAR

