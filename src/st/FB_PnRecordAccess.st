// Transport PROFINET thật: bọc CommFB.WRREC / CommFB.RDREC tới submodule CAP của AL1100.
// HIỆN LÀ KHUNG: chưa có PN Controller + AL1100 được duyệt (IP, station name, license) nên chưa gọi CommFB;
// mọi request trả lỗi dwSTAT_NOT_CONFIGURED để master báo rõ thay vì treo.
// TODO PROFINET:
//   1. Thêm AL1100 dưới PN_Controller, đặt bus cycle task = MainTask.
//   2. VAR: fbWr : CommFB.WRREC; fbRd : CommFB.RDREC;
//   3. dwId := CommFB.SUBSLOT_ID(EN := TRUE, ID := <AL1100>.DeviceID, SLOT := usiSlot, SUBSLOT := usiSubslot);
//      dwId = CommFB.Constants.INVALID_ID -> lỗi cấu hình.
//   4. Write: fbWr(REQ := xReq, ID := dwId, INDEX := iIndex, LEN := iLen, RECORD := <buffer>); xDone := fbWr.DONE ...
//      Read : fbRd(REQ := xReq, ID := dwId, INDEX := iIndex, MLEN := iMLen, RECORD := <buffer>); xValid := fbRd.VALID; iLen := fbRd.LEN ...
//      Kiểu chân RECORD (ANY / POINTER) phải xem trong Library Manager rồi copy buffer cho đúng.
//   5. Luôn viết đủ namespace CommFB.* (tránh trùng tên với lib Turck commfb*).
FUNCTION_BLOCK FB_PnRecordAccess IMPLEMENTS ITF_IolRecordAccess
VAR_INPUT
    usiSlot    : USINT := GVL_IolConst.usiAL1_SLOT;
    usiSubslot : USINT := GVL_IolConst.usiAL1_SUBSLOT_CAP;
END_VAR
VAR_OUTPUT
    xNotConfigured : BOOL := TRUE;    // TRUE khi FB còn là khung
END_VAR

(*---IMPL---*)
// Không có xử lý chu kỳ: toàn bộ việc nằm trong method Write/Read (gọi bởi FB_IolMaster).
xNotConfigured := TRUE;

METHOD Write : BOOL
VAR_INPUT
    xReq   : BOOL;
    dwId   : DWORD;
    iIndex : INT;
    iLen   : INT;
    pData  : POINTER TO BYTE;
END_VAR
VAR_OUTPUT
    xDone    : BOOL;
    xBusy    : BOOL;
    xError   : BOOL;
    dwStatus : DWORD;
END_VAR

(*---IMPL---*)
// TODO PROFINET: thay bằng CommFB.WRREC (xem ghi chú khai báo FB)
xDone  := FALSE;
xBusy  := FALSE;
xError := xReq;
IF xReq THEN
    dwStatus := GVL_IolConst.dwSTAT_NOT_CONFIGURED;
ELSE
    dwStatus := 0;
END_IF
Write := xReq;

METHOD Read : BOOL
VAR_INPUT
    xReq   : BOOL;
    dwId   : DWORD;
    iIndex : INT;
    iMLen  : INT;
    pData  : POINTER TO BYTE;
END_VAR
VAR_OUTPUT
    xValid   : BOOL;
    xBusy    : BOOL;
    xError   : BOOL;
    dwStatus : DWORD;
    iLen     : INT;
END_VAR

(*---IMPL---*)
// TODO PROFINET: thay bằng CommFB.RDREC (xem ghi chú khai báo FB)
xValid := FALSE;
xBusy  := FALSE;
xError := xReq;
iLen   := 0;
IF xReq THEN
    dwStatus := GVL_IolConst.dwSTAT_NOT_CONFIGURED;
ELSE
    dwStatus := 0;
END_IF
Read := xReq;

