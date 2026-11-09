{attribute 'qualified_only'}
// Bước trình tự gọi ISDU trong FB_IolDevBase
TYPE E_IolDevSeq :
(
    IDLE    := 0,   // chọn việc tiếp theo
    RUN     := 1,   // FB_IolCall đang chạy
    RELEASE := 2    // hạ Execute, chờ FB_IolCall về IDLE
) INT;
END_TYPE

