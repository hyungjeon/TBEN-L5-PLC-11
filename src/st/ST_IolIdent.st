// Thông tin nhận dạng chuẩn IO-Link (index 16..24)
TYPE ST_IolIdent :
STRUCT
    sVendorName  : STRING(64);   // 16
    sVendorText  : STRING(64);   // 17
    sProductName : STRING(64);   // 18
    sProductId   : STRING(64);   // 19
    sProductText : STRING(64);   // 20
    sSerialNo    : STRING(64);   // 21
    sHwRev       : STRING(64);   // 22
    sFwRev       : STRING(64);   // 23
    sAppTag      : STRING(64);   // 24
END_STRUCT
END_TYPE

