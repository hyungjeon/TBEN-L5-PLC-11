// Đọc Float32T IO-Link (IEEE754 big-endian): chép bit pattern, không đổi số học
FUNCTION F_IolGetR32BE : REAL
VAR_INPUT
    pBuf  : POINTER TO BYTE;
    uiOff : UINT;
END_VAR
VAR
    dwTmp : DWORD;
    pR    : POINTER TO REAL;
END_VAR

(*---IMPL---*)
dwTmp := F_IolGetU32BE(pBuf, uiOff);
pR := ADR(dwTmp);
F_IolGetR32BE := pR^;

