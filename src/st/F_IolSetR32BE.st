// Ghi REAL dạng Float32T big-endian
FUNCTION F_IolSetR32BE : BOOL
VAR_INPUT
    pBuf  : POINTER TO BYTE;
    uiOff : UINT;
    rVal  : REAL;
END_VAR
VAR
    pDw : POINTER TO DWORD;
END_VAR

(*---IMPL---*)
pDw := ADR(rVal);
F_IolSetR32BE := F_IolSetU32BE(pBuf, uiOff, pDw^);

