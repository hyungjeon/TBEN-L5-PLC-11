// Bố cục PDin O5D150 (16 bit, big-endian) - tách thành hằng để sửa theo IODD mà không đổi logic
TYPE ST_O5D150_PdLayout :
STRUCT
    usiOut1Bit       : USINT;      // bit OUT1 trong word PDin
    usiDistBitOffset : USINT;      // bit bắt đầu của Distance
    wDistMask        : WORD;       // mặt nạ sau khi dịch (12 bit = 16#0FFF)
    uiDistMin        : UINT;       // dải đo hợp lệ [cm]
    uiDistMax        : UINT;
    rGradient        : REAL;       // m / digit
END_STRUCT
END_TYPE

