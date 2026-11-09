// TRUE nếu STATUS RDREC/WRREC là "state conflict" (B5) hoặc "resource busy" (C3) -> master chưa xong, được retry
FUNCTION F_IolIsPnioBusy : BOOL
VAR_INPUT
    dwStatus : DWORD;          // ErrorCode, ErrorDecode, ErrorCode1, ErrorCode2 (byte cao -> thấp)
END_VAR
VAR
    bCode1 : BYTE;
END_VAR

(*---IMPL---*)
bCode1 := DWORD_TO_BYTE(SHR(dwStatus, 8));
F_IolIsPnioBusy := (bCode1 = 16#B5) OR (bCode1 = 16#C3);

