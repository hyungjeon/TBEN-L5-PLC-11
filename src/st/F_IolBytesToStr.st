// Chuyển StringT IO-Link (không có ký tự kết thúc) thành STRING, cắt ở 64 ký tự
FUNCTION F_IolBytesToStr : STRING(64)
VAR_INPUT
    pBuf  : POINTER TO BYTE;
    uiLen : UINT;
END_VAR
VAR
    sTmp : STRING(64);
    pDst : POINTER TO BYTE;
    i    : UINT;
    n    : UINT;
END_VAR

(*---IMPL---*)
sTmp := '';
IF pBuf <> 0 THEN
    n := MIN(uiLen, 64);
    pDst := ADR(sTmp);
    i := 0;
    WHILE i < n DO
        IF pBuf[i] = 0 THEN          // device có thể đệm 0 ở cuối
            EXIT;
        END_IF
        pDst[i] := pBuf[i];
        i := i + 1;
    END_WHILE
    pDst[i] := 0;
END_IF
F_IolBytesToStr := sTmp;

