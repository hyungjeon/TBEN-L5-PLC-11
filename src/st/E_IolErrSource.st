{attribute 'qualified_only'}
// Nguồn lỗi của 1 lần gọi IO-Link, để HMI biết lỗi nằm ở tầng nào
TYPE E_IolErrSource :
(
    NONE         := 0,
    PNIO         := 1,    // RDREC/WRREC trả STATUS lỗi (hoặc transport chưa cấu hình)
    IOL_MASTER   := 2,    // AL1100 báo IOL_M_ErrorCode
    IOL_DEVICE   := 3,    // cảm biến báo lỗi ISDU 0x80xx
    TIMEOUT      := 4,
    PARAM        := 5,    // tham số yêu cầu sai, không gửi đi
    LOCK         := 6,    // hết chỗ hàng đợi / không đăng ký được / bị reset
    FRAME        := 7,    // khung phản hồi sai
    NO_DEVICE    := 8,    // PQI.DA = 0: port không có thiết bị
    WRITE_LOCKED := 9,    // ghi bị khoá (chưa bật xMaintEnable)
    RANGE        := 10    // giá trị đặt ngoài dải IODD, chặn trước khi gửi
) INT;
END_TYPE

