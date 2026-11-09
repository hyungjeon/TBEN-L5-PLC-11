// Đọc 4 byte big-endian thành DWORD
FUNCTION F_IolGetU32BE : DWORD
VAR_INPUT
    pBuf  : POINTER TO BYTE;
    uiOff : UINT;
END_VAR

(*---IMPL---*)
IF pBuf = 0 THEN
    F_IolGetU32BE := 0;
    RETURN;
END_IF
F_IolGetU32BE := SHL(UINT_TO_DWORD(F_IolGetU16BE(pBuf, uiOff)), 16) OR UINT_TO_DWORD(F_IolGetU16BE(pBuf, uiOff + 2));

