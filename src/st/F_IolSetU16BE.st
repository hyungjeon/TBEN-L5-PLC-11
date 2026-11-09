// Ghi UINT big-endian vào buffer byte; FALSE nếu pBuf = 0
FUNCTION F_IolSetU16BE : BOOL
VAR_INPUT
    pBuf  : POINTER TO BYTE;
    uiOff : UINT;
    uiVal : UINT;
END_VAR

(*---IMPL---*)
IF pBuf = 0 THEN
    F_IolSetU16BE := FALSE;
    RETURN;
END_IF
pBuf[uiOff]     := WORD_TO_BYTE(SHR(UINT_TO_WORD(uiVal), 8));
pBuf[uiOff + 1] := UINT_TO_BYTE(uiVal);
F_IolSetU16BE := TRUE;

