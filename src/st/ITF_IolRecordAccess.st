// Ghi record (WRREC). Trả TRUE khi đã kết thúc (xDone hoặc xError).
METHOD Write : BOOL
VAR_INPUT
    xReq   : BOOL;
    dwId   : DWORD;                 // ID submodule (CommFB.SUBSLOT_ID), mock bỏ qua
    iIndex : INT;                   // record index (0xB400 truyền dạng INT)
    iLen   : INT;                   // số byte ghi
    pData  : POINTER TO BYTE;
END_VAR
VAR_OUTPUT
    xDone    : BOOL;
    xBusy    : BOOL;
    xError   : BOOL;
    dwStatus : DWORD;               // STATUS PNIO 4 byte
END_VAR

// Đọc record (RDREC). Trả TRUE khi đã kết thúc (xValid hoặc xError).
METHOD Read : BOOL
VAR_INPUT
    xReq   : BOOL;
    dwId   : DWORD;
    iIndex : INT;
    iMLen  : INT;                   // kích thước buffer nhận
    pData  : POINTER TO BYTE;
END_VAR
VAR_OUTPUT
    xValid   : BOOL;
    xBusy    : BOOL;
    xError   : BOOL;
    dwStatus : DWORD;
    iLen     : INT;                 // số byte nhận được
END_VAR

// Trừu tượng hoá đọc/ghi record PROFINET (CommFB.WRREC/RDREC thật hoặc mock Simulation)
// Quy ước như CommFB: giữ xReq = TRUE tới khi có kết quả, hạ xReq ít nhất 1 lần gọi trước request mới; gọi mỗi chu kỳ đúng 1 lần.
INTERFACE ITF_IolRecordAccess

