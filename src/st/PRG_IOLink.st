// IO-Link qua AL1100: chọn transport, gọi device + master, cầu nối GVL_HMI_IOL, alarm. Gọi cuối PLC_PRG (MainTask).
PROGRAM PRG_IOLink
VAR
    fbDevP1  : FB_Dev_O5D150;              // O5D150 ở port GVL_IolConst.usiPORT_O5D150
    itfSel   : ITF_IolRecordAccess;
    tonNoDev : TON;                        // trễ alarm port không có thiết bị
    tonPdInv : TON;                        // trễ alarm PD không hợp lệ
    i        : INT;
END_VAR

(*---IMPL---*)
// ---------- 1. Chọn transport: mock trên Simulation hoặc PROFINET thật ----------
IF GVL_IolSys.xSimMode THEN
    itfSel := GVL_IolSys.fbMockAL1;
ELSE
    itfSel := GVL_IolSys.fbPnAL1;
END_IF

// ---------- 2. Device port 1: O5D150 (gọi trước master để request mới được xử lý ngay chu kỳ này) ----------
fbDevP1.refMaster REF= GVL_IolSys.fbAL1;
fbDevP1(
    usiPort          := GVL_IolConst.usiPORT_O5D150,
    bPQI             := GVL_IO.bAL1_P1_PQI,
    abPdIn           := GVL_IO.abAL1_P1_In,
    xWriteEnable     := GVL_HMI_IOL.xMaintEnable,
    xResetErr        := GVL_HMI_IOL.stO5D150.xCmdResetErr,
    xAlignMode       := GVL_HMI_IOL.stO5D150.xAlignMode,
    xCmdReadAll      := GVL_HMI_IOL.stO5D150.xCmdReadAll,
    xCmdReadIdent    := GVL_HMI_IOL.stO5D150.xCmdReadIdent,
    xCmdWriteSP1     := GVL_HMI_IOL.stO5D150.xCmdWriteSP1,
    xCmdWriteLogic   := GVL_HMI_IOL.stO5D150.xCmdWriteLogic,
    xCmdWriteLaser   := GVL_HMI_IOL.stO5D150.xCmdWriteLaser,
    xCmdWriteDisplay := GVL_HMI_IOL.stO5D150.xCmdWriteDisplay,
    xCmdTestEvt1On   := GVL_HMI_IOL.stO5D150.xCmdTestEvt1On,
    xCmdTestEvt1Off  := GVL_HMI_IOL.stO5D150.xCmdTestEvt1Off,
    xCmdTestEvt2On   := GVL_HMI_IOL.stO5D150.xCmdTestEvt2On,
    xCmdTestEvt2Off  := GVL_HMI_IOL.stO5D150.xCmdTestEvt2Off,
    xCmdReadEvents   := GVL_HMI_IOL.stO5D150.xCmdReadEvents,
    uiSetSP1         := GVL_HMI_IOL.stO5D150.uiSetSP1,
    usiSetLogic      := GVL_HMI_IOL.stO5D150.usiSetLogic,
    usiSetLaser      := GVL_HMI_IOL.stO5D150.usiSetLaser,
    usiSetDisplay    := GVL_HMI_IOL.stO5D150.usiSetDisplay);

// ---------- 3. Master AL1100 ----------
GVL_IolSys.fbAL1(
    itfRec := itfSel,
    xEnable := TRUE,
    xReset := GVL_HMI_IOL.xCmdResetMaster AND GVL_HMI_IOL.xMaintEnable);

// ---------- 4. Lệnh 1 lần từ HMI: xoá sau khi FB đã nhận sườn ----------
GVL_HMI_IOL.stO5D150.xCmdReadAll      := FALSE;
GVL_HMI_IOL.stO5D150.xCmdReadIdent    := FALSE;
GVL_HMI_IOL.stO5D150.xCmdWriteSP1     := FALSE;
GVL_HMI_IOL.stO5D150.xCmdWriteLogic   := FALSE;
GVL_HMI_IOL.stO5D150.xCmdWriteLaser   := FALSE;
GVL_HMI_IOL.stO5D150.xCmdWriteDisplay := FALSE;
GVL_HMI_IOL.stO5D150.xCmdTestEvt1On   := FALSE;
GVL_HMI_IOL.stO5D150.xCmdTestEvt1Off  := FALSE;
GVL_HMI_IOL.stO5D150.xCmdTestEvt2On   := FALSE;
GVL_HMI_IOL.stO5D150.xCmdTestEvt2Off  := FALSE;
GVL_HMI_IOL.stO5D150.xCmdReadEvents   := FALSE;
GVL_HMI_IOL.stO5D150.xCmdResetErr     := FALSE;
GVL_HMI_IOL.xCmdResetMaster           := FALSE;

// ---------- 5. Trạng thái lên HMI ----------
GVL_HMI_IOL.stO5D150.uiDistance_cm := fbDevP1.stPd.uiDistance_cm;
GVL_HMI_IOL.stO5D150.rDistance_m   := fbDevP1.stPd.rDistance_m;
GVL_HMI_IOL.stO5D150.xOut1         := fbDevP1.stPd.xOut1;
GVL_HMI_IOL.stO5D150.xPdValid      := fbDevP1.stPd.xPdValid;
GVL_HMI_IOL.stO5D150.xOutOfRange   := fbDevP1.stPd.xOutOfRange;
GVL_HMI_IOL.stO5D150.xPQ           := fbDevP1.stDiag.xPQ;
GVL_HMI_IOL.stO5D150.xDA           := fbDevP1.stDiag.xDA;
GVL_HMI_IOL.stO5D150.xDE           := fbDevP1.stDiag.xDE;

GVL_HMI_IOL.stO5D150.uiSP1         := DINT_TO_UINT(fbDevP1.aVal[E_O5D150_Param.SP1].diRaw);
GVL_HMI_IOL.stO5D150.xParamValid   := fbDevP1.aVal[E_O5D150_Param.SP1].xValid;
GVL_HMI_IOL.stO5D150.usiLogic      := DINT_TO_USINT(fbDevP1.aVal[E_O5D150_Param.CFG_LOGIC].diRaw);
GVL_HMI_IOL.stO5D150.uiLimitMin_cm := fbDevP1.uiLimitMin_cm;
GVL_HMI_IOL.stO5D150.uiLimitMax_cm := fbDevP1.uiLimitMax_cm;
GVL_HMI_IOL.stO5D150.usiAlign      := DINT_TO_USINT(fbDevP1.aVal[E_O5D150_Param.ALIGN].diRaw);
GVL_HMI_IOL.stO5D150.usiLaser      := DINT_TO_USINT(fbDevP1.aVal[E_O5D150_Param.LASER].diRaw);
GVL_HMI_IOL.stO5D150.usiDisplay    := DINT_TO_USINT(fbDevP1.aVal[E_O5D150_Param.DISPLAY].diRaw);

GVL_HMI_IOL.stO5D150.sVendor  := fbDevP1.stIdent.sVendorName;
GVL_HMI_IOL.stO5D150.sProduct := fbDevP1.stIdent.sProductName;
GVL_HMI_IOL.stO5D150.sSerial  := fbDevP1.stIdent.sSerialNo;
GVL_HMI_IOL.stO5D150.sFwRev   := fbDevP1.stIdent.sFwRev;

FOR i := 0 TO GVL_O5D150_Def.iEVT_COUNT - 1 DO
    GVL_HMI_IOL.stO5D150.axEvtActive[i] := fbDevP1.axEvtActive[i];
END_FOR
GVL_HMI_IOL.stO5D150.uiEvtCount           := fbDevP1.uiEvtCount;
GVL_HMI_IOL.stO5D150.wUnknownEvt          := fbDevP1.wUnknownEvt;
GVL_HMI_IOL.stO5D150.xEvtListNotSupported := fbDevP1.xEvtListNotSupported;

GVL_HMI_IOL.stO5D150.xBusy        := fbDevP1.xBusy;
GVL_HMI_IOL.stO5D150.xError       := fbDevP1.xLastError;
GVL_HMI_IOL.stO5D150.uiDevErr     := fbDevP1.uiLastDevErr;
GVL_HMI_IOL.stO5D150.wsErrText    := fbDevP1.wsLastErr;
GVL_HMI_IOL.stO5D150.xWriteLocked := NOT GVL_HMI_IOL.xMaintEnable;

GVL_HMI_IOL.eMasterState := GVL_IolSys.fbAL1.eState;
GVL_HMI_IOL.udiCallCount := GVL_IolSys.fbAL1.udiCallCount;
GVL_HMI_IOL.udiErrCount  := GVL_IolSys.fbAL1.udiErrCount;
GVL_HMI_IOL.xSimMode     := GVL_IolSys.xSimMode;

// ---------- 6. Alarm ----------
tonNoDev(IN := NOT fbDevP1.stDiag.xDA, PT := T#2S);
tonPdInv(IN := fbDevP1.stDiag.xDA AND NOT fbDevP1.stDiag.xPQ, PT := T#1S);
GVL_HMI_IOL.xAlmP1_NoDevice  := tonNoDev.Q;
GVL_HMI_IOL.xAlmP1_PdInvalid := tonPdInv.Q;
GVL_HMI_IOL.xAlmP1_DevErr    := fbDevP1.stDiag.xDE;
GVL_HMI_IOL.xAlmP1_EvtError  := fbDevP1.xEvtErrorActive;
GVL_HMI_IOL.xAlmIolCallErr   := fbDevP1.xLastError;
GVL_HMI_IOL.xAlmMasterStuck  := GVL_IolSys.fbAL1.eState = E_IolCallState.STUCK;

GVL_HMI_IOL.xAlarmAny   := GVL_HMI_IOL.xAlmMasterStuck OR GVL_HMI_IOL.xAlmP1_EvtError;
GVL_HMI_IOL.xWarningAny := GVL_HMI_IOL.xAlmP1_NoDevice OR GVL_HMI_IOL.xAlmP1_PdInvalid
                           OR GVL_HMI_IOL.xAlmP1_DevErr OR GVL_HMI_IOL.xAlmIolCallErr;

