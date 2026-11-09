// 1 request ISDU gửi qua master
TYPE ST_IolRequest :
STRUCT
    usiPort     : USINT;                                   // 0 = master, 1..4 = port
    eService    : E_IolService := E_IolService.READ;
    uiIndex     : UINT;
    usiSubindex : USINT;                                   // 0 = cả index
    uiLen       : UINT;                                    // số byte dữ liệu ghi (READ = 0)
    abData      : ARRAY[0..GVL_IolConst.uiMAX_DATA - 1] OF BYTE;
END_STRUCT
END_TYPE

