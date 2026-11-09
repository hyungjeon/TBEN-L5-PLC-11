// Ghi DWORD big-endian (4 byte) vào buffer
FUNCTION F_IolSetU32BE : BOOL
VAR_INPUT
    pBuf  : POINTER TO BYTE;
    uiOff : UINT;
    dwVal : DWORD;
END_VAR

(*---IMPL---*)
IF pBuf = 0 THEN
    F_IolSetU32BE := FALSE;
    RETURN;
END_IF
F_IolSetU16BE(pBuf, uiOff, DWORD_TO_UINT(SHR(dwVal, 16)));
F_IolSetU16BE(pBuf, uiOff + 2, DWORD_TO_UINT(dwVal));
F_IolSetU32BE := TRUE;

