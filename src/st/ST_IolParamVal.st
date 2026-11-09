// Giá trị runtime của 1 tham số (không RETAIN: nguồn thật là cảm biến)
TYPE ST_IolParamVal :
STRUCT
    diRaw  : DINT;      // giá trị đọc về gần nhất
    xValid : BOOL;      // lần đọc gần nhất thành công
    uiErr  : UINT;      // 0x80xx = lỗi device, 0xFFnn = lỗi nội bộ (nn = E_IolErrSource)
    diSet  : DINT;      // giá trị đang chờ ghi
    xDirty : BOOL;      // TRUE từ lúc yêu cầu ghi tới khi ghi xong
END_STRUCT
END_TYPE

