// Định nghĩa 1 tham số lấy từ IODD (bảng hằng trong GVL_<Model>_Def)
TYPE ST_IolParamDef :
STRUCT
    sName       : STRING(24);                  // tên theo IODD
    uiIndex     : UINT;
    usiSubindex : USINT;                       // 0 = cả index
    eType       : E_IolDataType;
    eAccess     : E_IolAccess;
    diMin       : DINT;                        // dải hợp lệ khi ghi (raw = đơn vị kỹ thuật)
    diMax       : DINT;
    diDefault   : DINT;
    sUnit       : STRING(8);
    xInReadAll  : BOOL := TRUE;                // có đọc trong ReadAll không
END_STRUCT
END_TYPE

