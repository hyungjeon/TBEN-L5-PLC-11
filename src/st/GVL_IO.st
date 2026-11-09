// Ngõ vào/ra DXP của TBEN-L5-PLC-11 (map trong Local_IO > DXP > I/O Mapping)
// Đầu nối: C4 = Ch8/Ch9, C5 = Ch10/Ch11, C6 = Ch12/Ch13, C7 = Ch14/Ch15
VAR_GLOBAL
    xQ_Ch8  : BOOL;   // ngõ ra DXP Ch8  (C4)
    xQ_Ch9  : BOOL;   // ngõ ra DXP Ch9  (C4)
    xQ_Ch10 : BOOL;   // ngõ ra DXP Ch10 (C5)
    xQ_Ch11 : BOOL;   // ngõ ra DXP Ch11 (C5)
    xQ_Ch12 : BOOL;   // ngõ ra DXP Ch12 (C6)
    xQ_Ch13 : BOOL;   // ngõ ra DXP Ch13 (C6)
    xQ_Ch14 : BOOL;   // ngõ ra DXP Ch14 (C7)
    xQ_Ch15 : BOOL;   // ngõ ra DXP Ch15 (C7)

    xI_Ch8  : BOOL;   // đọc lại mức tín hiệu DXP Ch8
    xI_Ch9  : BOOL;   // đọc lại mức tín hiệu DXP Ch9
    xI_Ch10 : BOOL;   // đọc lại mức tín hiệu DXP Ch10
    xI_Ch11 : BOOL;   // đọc lại mức tín hiệu DXP Ch11
    xI_Ch12 : BOOL;   // đọc lại mức tín hiệu DXP Ch12
    xI_Ch13 : BOOL;   // đọc lại mức tín hiệu DXP Ch13
    xI_Ch14 : BOOL;   // đọc lại mức tín hiệu DXP Ch14
    xI_Ch15 : BOOL;   // đọc lại mức tín hiệu DXP Ch15

    // IO-Link master ifm AL1100 (PROFINET), port 1 = O5D150.
    // TODO PROFINET: map 2 biến này vào Input data / PQI của submodule Port 1 khi thêm AL1100; hiện là biến thường để Write/Force trên Simulation.
    abAL1_P1_In : ARRAY[0..1] OF BYTE;   // PDin O5D150 big-endian: byte 0 = MSB (Distance bit 15..4, OUT1 bit 0)
    bAL1_P1_PQI : BYTE;                  // Port Qualifier: bit7 PQ, bit6 DE, bit5 DC, bit4 DA (16#90 = PQ + DA)
END_VAR

