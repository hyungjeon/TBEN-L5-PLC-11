// PDin O5D150 đã giải mã
TYPE ST_O5D150_PdIn :
STRUCT
    wRaw          : WORD;     // word PDin ghép big-endian
    uiDistance_cm : UINT;     // giữ giá trị cũ khi PD không hợp lệ
    rDistance_m   : REAL;
    xOut1         : BOOL;     // FALSE (fail-safe) khi PD không hợp lệ
    xPdValid      : BOOL;     // PQ AND DA
    xOutOfRange   : BOOL;     // ngoài 5..200 cm (không có vật / quá gần)
END_STRUCT
END_TYPE

