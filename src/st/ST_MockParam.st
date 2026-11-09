// 1 index trong bảng dữ liệu giả lập của FB_MockRecordAccess
TYPE ST_MockParam :
STRUCT
    uiIndex : UINT;
    eAccess : E_IolAccess;
    uiLen   : UINT;                      // số byte của cả index
    abData  : ARRAY[0..63] OF BYTE;      // big-endian như trên dây
END_STRUCT
END_TYPE

