{attribute 'qualified_only'}
// Loại việc ISDU đang chạy trong FB_IolDevBase
TYPE E_IolDevJob :
(
    NONE     := 0,
    IDENT    := 1,  // đọc index 16..24
    PARAM_RD := 2,  // đọc 1 tham số trong bảng
    PARAM_WR := 3,  // ghi 1 tham số trong bảng
    CUSTOM   := 4   // ISDU tự do của lớp con (system command, event list...)
) INT;
END_TYPE

