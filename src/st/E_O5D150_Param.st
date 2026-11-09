{attribute 'qualified_only'}
// Vị trí tham số trong bảng GVL_O5D150_Def.aParamDef (không phải IO-Link index)
TYPE E_O5D150_Param :
(
    SP1       := 0,   // index 60 sub 1
    CFG_LOGIC := 1,   // index 61 sub 1
    LIMITS    := 2,   // index 64 (min, max) - không đặt tên LIMIT vì trùng hàm chuẩn
    ALIGN     := 3,   // index 69
    LASER     := 4,   // index 80
    DISPLAY   := 5,   // index 96
    KEYLOCK   := 6,   // index 100
    DFO       := 7,   // index 74
    DS        := 8,   // index 76
    DR        := 9    // index 78
) INT;
END_TYPE

