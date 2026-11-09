// Kết quả 1 request ISDU master trả cho client
TYPE ST_IolResult :
STRUCT
    xError         : BOOL;
    eErrSource     : E_IolErrSource;
    dwPnioStatus   : DWORD;                                // STATUS RDREC/WRREC
    uiIolMasterErr : UINT;                                 // IOL_M_ErrorCode
    uiIolDevErr    : UINT;                                 // lỗi ISDU device 0x80xx
    uiLen          : UINT;                                 // số byte dữ liệu đọc về
    abData         : ARRAY[0..GVL_IolConst.uiMAX_DATA - 1] OF BYTE;
END_STRUCT
END_TYPE

