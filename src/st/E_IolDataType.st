{attribute 'qualified_only'}
// Kiểu dữ liệu tham số theo IODD (giá trị trên dây là big-endian)
TYPE E_IolDataType :
(
    U8    := 0,
    U16   := 1,
    U32   := 2,
    I8    := 3,
    I16   := 4,
    I32   := 5,
    STR   := 6,
    OCTET := 7    // record nhiều trường, lớp con tự tách (vd Limit index 64)
) INT;
END_TYPE

