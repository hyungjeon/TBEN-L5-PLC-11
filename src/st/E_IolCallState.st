{attribute 'qualified_only'}
// Trạng thái state machine IOL_CALL của FB_IolMaster
TYPE E_IolCallState :
(
    IDLE      := 0,   // rảnh, chờ request trong FIFO
    WRITE_REQ := 1,   // WRREC khung IOL_CALL vào record CAP 0xB400
    RETRY_WR  := 2,   // master báo bận -> chờ rồi ghi lại
    READ_WAIT := 3,   // REQ đã hạ, chờ trước khi RDREC phản hồi
    READ_REQ  := 4,   // RDREC đọc phản hồi + kiểm khung
    DONE      := 5,   // trả kết quả cho client (1 chu kỳ)
    ERROR     := 6,   // trả lỗi cho client (1 chu kỳ)
    TIMEOUT   := 7,   // quá hạn: hạ REQ, chờ transport hết BUSY
    STUCK     := 8    // transport kẹt BUSY > 1 s, chỉ thoát bằng xReset
) INT;
END_TYPE

