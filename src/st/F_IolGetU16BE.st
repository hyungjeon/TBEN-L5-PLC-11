// Đọc UINT big-endian (IO-Link/PROFINET) từ buffer byte - TBEN là ARM little-endian nên không ép kiểu trực tiếp
FUNCTION F_IolGetU16BE : UINT
VAR_INPUT
    pBuf  : POINTER TO BYTE;
    uiOff : UINT;               // vị trí byte MSB
END_VAR

(*---IMPL---*)
IF pBuf = 0 THEN
    F_IolGetU16BE := 0;
    RETURN;
END_IF
F_IolGetU16BE := WORD_TO_UINT(SHL(BYTE_TO_WORD(pBuf[uiOff]), 8) OR BYTE_TO_WORD(pBuf[uiOff + 1]));

