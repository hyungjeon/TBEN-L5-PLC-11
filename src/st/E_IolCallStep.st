{attribute 'qualified_only'}
// Bước handshake của client FB_IolCall
TYPE E_IolCallStep :
(
    IDLE := 0,
    WAIT := 1,    // đã vào hàng đợi master, chờ kết quả
    DONE := 2,
    ERR  := 3
) INT;
END_TYPE

