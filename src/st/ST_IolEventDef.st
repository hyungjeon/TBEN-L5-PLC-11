// Định nghĩa 1 event của device (từ IODD)
TYPE ST_IolEventDef :
STRUCT
    wCode  : WORD;
    sName  : STRING(12);        // tên ngắn trên màn hình cảm biến
    wsText : WSTRING(48);       // mô tả cho HMI
    eType  : E_IolEvtType;
END_STRUCT
END_TYPE

