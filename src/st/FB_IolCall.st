// Client IO-Link Call kiểu PLCopen: sườn lên xExecute -> xBusy -> xDone/xError (giữ tới khi xExecute = FALSE,
// tối thiểu 1 chu kỳ nếu xExecute đã rớt). Request đi qua hàng đợi FB_IolMaster.
FUNCTION_BLOCK FB_IolCall
VAR_INPUT
    refMaster   : REFERENCE TO FB_IolMaster;
    xExecute    : BOOL;
    usiPort     : USINT;                   // 1..4 (0 = master)
    eService    : E_IolService := E_IolService.READ;
    uiIndex     : UINT;
    usiSubindex : USINT;
    pData       : POINTER TO BYTE;         // WRITE: dữ liệu ghi; READ: buffer nhận
    uiDataLen   : UINT;                    // WRITE: số byte ghi; READ: kích thước buffer
END_VAR
VAR_OUTPUT
    xDone          : BOOL;
    xBusy          : BOOL;
    xError         : BOOL;
    uiLenRead      : UINT;
    eErrSource     : E_IolErrSource;
    dwPnioStatus   : DWORD;
    uiIolMasterErr : UINT;
    uiIolDevErr    : UINT;
    wsErrText      : WSTRING(80);
END_VAR
VAR
    rtExec  : R_TRIG;
    eStep   : E_IolCallStep;
    hHandle : USINT;                       // handle đăng ký với master (1 lần)
    stReq   : ST_IolRequest;
    stRes   : ST_IolResult;
    tonWait : TON;                         // timeout phía client, bao cả thời gian chờ hàng đợi
    i       : INT;
    n       : UINT;
END_VAR

(*---IMPL---*)
rtExec(CLK := xExecute);

CASE eStep OF
    E_IolCallStep.IDLE:
        xDone  := FALSE;
        xError := FALSE;
        xBusy  := FALSE;
        tonWait(IN := FALSE);
        IF rtExec.Q THEN
            uiLenRead := 0;
            eErrSource := E_IolErrSource.NONE;
            dwPnioStatus := 0;
            uiIolMasterErr := 0;
            uiIolDevErr := 0;
            wsErrText := "";
            // kiểm tham số trước khi gửi
            IF NOT __ISVALIDREF(refMaster) OR usiPort > 4 OR pData = 0
               OR uiDataLen > GVL_IolConst.uiMAX_DATA
               OR (eService = E_IolService.WRITE AND uiDataLen = 0) THEN
                SetError(E_IolErrSource.PARAM);
            ELSE
                IF hHandle = 0 THEN
                    hHandle := refMaster.Register();
                END_IF
                stReq.usiPort     := usiPort;
                stReq.eService    := eService;
                stReq.uiIndex     := uiIndex;
                stReq.usiSubindex := usiSubindex;
                stReq.uiLen       := 0;
                IF eService = E_IolService.WRITE THEN
                    stReq.uiLen := uiDataLen;
                    FOR i := 0 TO UINT_TO_INT(uiDataLen) - 1 DO
                        stReq.abData[i] := pData[i];
                    END_FOR
                END_IF
                IF hHandle = 0 THEN
                    SetError(E_IolErrSource.LOCK);
                ELSIF refMaster.Submit(hHandle := hHandle, stReq := stReq) THEN
                    xBusy := TRUE;
                    eStep := E_IolCallStep.WAIT;
                ELSE
                    SetError(E_IolErrSource.LOCK);
                END_IF
            END_IF
        END_IF

    E_IolCallStep.WAIT:
        xBusy := TRUE;
        tonWait(IN := TRUE, PT := refMaster.tTimeout * 2);
        IF refMaster.Poll(hHandle := hHandle, stRes := stRes) THEN
            tonWait(IN := FALSE);
            xBusy := FALSE;
            IF stRes.xError THEN
                dwPnioStatus   := stRes.dwPnioStatus;
                uiIolMasterErr := stRes.uiIolMasterErr;
                uiIolDevErr    := stRes.uiIolDevErr;
                SetError(stRes.eErrSource);
            ELSE
                IF eService = E_IolService.READ THEN
                    n := MIN(stRes.uiLen, uiDataLen);
                    FOR i := 0 TO UINT_TO_INT(n) - 1 DO
                        pData[i] := stRes.abData[i];
                    END_FOR
                    uiLenRead := n;
                END_IF
                xDone := TRUE;
                eStep := E_IolCallStep.DONE;
            END_IF
        ELSIF tonWait.Q THEN
            tonWait(IN := FALSE);
            refMaster.Cancel(hHandle := hHandle);
            xBusy := FALSE;
            SetError(E_IolErrSource.TIMEOUT);
        END_IF

    E_IolCallStep.DONE:
        xBusy := FALSE;
        xDone := TRUE;
        IF NOT xExecute THEN
            eStep := E_IolCallStep.IDLE;      // chu kỳ sau IDLE mới xoá xDone
        END_IF

    E_IolCallStep.ERR:
        xBusy  := FALSE;
        xError := TRUE;
        IF NOT xExecute THEN
            eStep := E_IolCallStep.IDLE;
        END_IF
END_CASE

// Chuyển sang ERR, ghi nguồn lỗi + chuỗi hiển thị
METHOD PRIVATE SetError
VAR_INPUT
    eSrc : E_IolErrSource;
END_VAR

(*---IMPL---*)
eErrSource := eSrc;
wsErrText  := F_IolErrText(eSrc, uiIolMasterErr, uiIolDevErr, dwPnioStatus);
xBusy  := FALSE;
xDone  := FALSE;
xError := TRUE;
eStep  := E_IolCallStep.ERR;

