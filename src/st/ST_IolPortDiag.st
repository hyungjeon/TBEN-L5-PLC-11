// Port Qualifier (PQI) AL1100 đã giải mã - bit theo GSDML ifm AL1100
TYPE ST_IolPortDiag :
STRUCT
    bPQI : BYTE;
    xDI4 : BOOL;   // bit0 trạng thái chân 4 (DI)
    xDI2 : BOOL;   // bit1 trạng thái chân 2 (DI)
    xNP  : BOOL;   // bit2
    xSV  : BOOL;   // bit3
    xDA  : BOOL;   // bit4 Device Available
    xDC  : BOOL;   // bit5
    xDE  : BOOL;   // bit6 Device Error
    xPQ  : BOOL;   // bit7 Port Qualifier: PDin hợp lệ
END_STRUCT
END_TYPE

