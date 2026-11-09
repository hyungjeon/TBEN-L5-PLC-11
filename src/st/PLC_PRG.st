PROGRAM PLC_PRG
VAR
    fbSeq    : FB_OutSeq;     // bộ tạo trình tự ngõ ra
    xRunReq  : BOOL;          // chốt Start/Stop
    byManual : BYTE;          // ảnh ngõ ra tay
    i        : INT;
END_VAR

(*---IMPL---*)
// ---------- 1. Start / Stop (Stop ưu tiên) ----------
IF GVL_HMI.xCmdStop THEN
    xRunReq := FALSE;
ELSIF GVL_HMI.xCmdStart THEN
    xRunReq := TRUE;
END_IF
GVL_HMI.xCmdStart := FALSE;
GVL_HMI.xCmdStop  := FALSE;

// ---------- 2. Giới hạn thông số từ visu ----------
GVL_HMI.iModeSel  := LIMIT(0, GVL_HMI.iModeSel, 13);
GVL_HMI.udiStepMs := LIMIT(50, GVL_HMI.udiStepMs, 2000);
GVL_HMI.udiDemoS  := LIMIT(2, GVL_HMI.udiDemoS, 60);

byManual := 0;
FOR i := 0 TO 7 DO
    IF GVL_HMI.axManual[i] THEN
        byManual := byManual OR SHL(BYTE#1, i);
    END_IF
END_FOR

// ---------- 3. Tạo trình tự (MANUAL chạy không cần Start) ----------
fbSeq(
    xRun      := (xRunReq AND GVL_HMI.iModeSel <> E_SeqMode.OFF) OR GVL_HMI.iModeSel = E_SeqMode.MANUAL,
    eMode     := GVL_HMI.iModeSel,
    tStep     := UDINT_TO_TIME(GVL_HMI.udiStepMs),
    tDemoHold := UDINT_TO_TIME(GVL_HMI.udiDemoS * 1000),
    xReverse  := GVL_HMI.xReverse,
    byManual  := byManual);

// ---------- 4. Ghi ngõ ra DXP ----------
GVL_IO.xQ_Ch8  := fbSeq.byOut.0;
GVL_IO.xQ_Ch9  := fbSeq.byOut.1;
GVL_IO.xQ_Ch10 := fbSeq.byOut.2;
GVL_IO.xQ_Ch11 := fbSeq.byOut.3;
GVL_IO.xQ_Ch12 := fbSeq.byOut.4;
GVL_IO.xQ_Ch13 := fbSeq.byOut.5;
GVL_IO.xQ_Ch14 := fbSeq.byOut.6;
GVL_IO.xQ_Ch15 := fbSeq.byOut.7;

// ---------- 5. Trạng thái lên visu ----------
GVL_HMI.xRunning    := fbSeq.xRun;
GVL_HMI.byOut       := fbSeq.byOut;
GVL_HMI.uiStep      := fbSeq.uiStep;
GVL_HMI.iModeActive := fbSeq.eActive;
FOR i := 0 TO 7 DO
    GVL_HMI.axOut[i] := (SHR(fbSeq.byOut, i) AND 1) <> 0;
END_FOR
FOR i := 0 TO 13 DO
    GVL_HMI.axModeSel[i] := (GVL_HMI.iModeSel = i);
END_FOR
GVL_HMI.xNotManual := (GVL_HMI.iModeSel <> E_SeqMode.MANUAL);
GVL_HMI.axFb[0] := GVL_IO.xI_Ch8;
GVL_HMI.axFb[1] := GVL_IO.xI_Ch9;
GVL_HMI.axFb[2] := GVL_IO.xI_Ch10;
GVL_HMI.axFb[3] := GVL_IO.xI_Ch11;
GVL_HMI.axFb[4] := GVL_IO.xI_Ch12;
GVL_HMI.axFb[5] := GVL_IO.xI_Ch13;
GVL_HMI.axFb[6] := GVL_IO.xI_Ch14;
GVL_HMI.axFb[7] := GVL_IO.xI_Ch15;

CASE fbSeq.eActive OF
    E_SeqMode.OFF:       GVL_HMI.sModeName := "OFF - Tắt";
    E_SeqMode.CHASE:     GVL_HMI.sModeName := "Chạy đuổi";
    E_SeqMode.PINGPONG:  GVL_HMI.sModeName := "Qua lại";
    E_SeqMode.FILL:      GVL_HMI.sModeName := "Sáng dồn / tắt dần";
    E_SeqMode.STACK:     GVL_HMI.sModeName := "Xếp chồng";
    E_SeqMode.BLINK:     GVL_HMI.sModeName := "Nhấp nháy";
    E_SeqMode.ALTERNATE: GVL_HMI.sModeName := "Chẵn / lẻ";
    E_SeqMode.BINARY:    GVL_HMI.sModeName := "Đếm nhị phân";
    E_SeqMode.CENTER:    GVL_HMI.sModeName := "Từ giữa ra";
    E_SeqMode.WAVE:      GVL_HMI.sModeName := "Sóng 3 đèn";
    E_SeqMode.PAIR:      GVL_HMI.sModeName := "Cặp đèn";
    E_SeqMode.RANDOM:    GVL_HMI.sModeName := "Ngẫu nhiên";
    E_SeqMode.MANUAL:    GVL_HMI.sModeName := "Bật tay";
END_CASE

// ---------- 6. IO-Link AL1100 / O5D150 ----------
PRG_IOLink();

