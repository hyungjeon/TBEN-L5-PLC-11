{attribute 'qualified_only'}
// Bảng hằng O5D150 lấy từ IODD ifm-000174-20210526-IODD1.1.xml (vendor 310, device 372)
VAR_GLOBAL CONSTANT
    uiPDIN_LEN   : UINT := 2;
    stPdLayout   : ST_O5D150_PdLayout := (usiOut1Bit := 0, usiDistBitOffset := 4, wDistMask := 16#0FFF,
                                          uiDistMin := 5, uiDistMax := 200, rGradient := 0.01);

    iPARAM_COUNT : INT := 10;   // = số phần tử E_O5D150_Param
    aParamDef    : ARRAY[0..9] OF ST_IolParamDef := [
        (sName := 'SP1',     uiIndex := 60,  usiSubindex := 1, eType := E_IolDataType.U16, eAccess := E_IolAccess.RW, diMin := 5, diMax := 200,  diDefault := 100, sUnit := 'cm', xInReadAll := TRUE),
        (sName := 'Logic',   uiIndex := 61,  usiSubindex := 1, eType := E_IolDataType.U8,  eAccess := E_IolAccess.RW, diMin := 0, diMax := 1,    diDefault := 0,   sUnit := '',   xInReadAll := TRUE),
        (sName := 'Limit',   uiIndex := 64,  usiSubindex := 0, eType := E_IolDataType.U32, eAccess := E_IolAccess.RO, diMin := 0, diMax := 0,    diDefault := 0,   sUnit := 'cm', xInReadAll := TRUE),
        (sName := 'Align',   uiIndex := 69,  usiSubindex := 0, eType := E_IolDataType.U8,  eAccess := E_IolAccess.RO, diMin := 0, diMax := 100,  diDefault := 0,   sUnit := '%',  xInReadAll := TRUE),
        (sName := 'Laser',   uiIndex := 80,  usiSubindex := 0, eType := E_IolDataType.U8,  eAccess := E_IolAccess.RW, diMin := 0, diMax := 1,    diDefault := 1,   sUnit := '',   xInReadAll := TRUE),
        (sName := 'Display', uiIndex := 96,  usiSubindex := 0, eType := E_IolDataType.U8,  eAccess := E_IolAccess.RW, diMin := 0, diMax := 2,    diDefault := 1,   sUnit := '',   xInReadAll := TRUE),
        (sName := 'KeyLock', uiIndex := 100, usiSubindex := 0, eType := E_IolDataType.U8,  eAccess := E_IolAccess.RW, diMin := 0, diMax := 1,    diDefault := 1,   sUnit := '',   xInReadAll := TRUE),
        (sName := 'dFO',     uiIndex := 74,  usiSubindex := 0, eType := E_IolDataType.U16, eAccess := E_IolAccess.RW, diMin := 0, diMax := 2000, diDefault := 0,   sUnit := '',   xInReadAll := TRUE),
        (sName := 'dS',      uiIndex := 76,  usiSubindex := 0, eType := E_IolDataType.U16, eAccess := E_IolAccess.RW, diMin := 0, diMax := 2000, diDefault := 0,   sUnit := '',   xInReadAll := TRUE),
        (sName := 'dr',      uiIndex := 78,  usiSubindex := 0, eType := E_IolDataType.U16, eAccess := E_IolAccess.RW, diMin := 0, diMax := 2000, diDefault := 0,   sUnit := '',   xInReadAll := TRUE)
    ];

    // --- System Command (index 2, UINT8, write only) ---
    uiIDX_SYS_CMD        : UINT  := 2;
    usiSC_FACTORY_RESET  : USINT := 130;
    usiSC_TEST_EVT1_ON   : USINT := 240;   // Test Event 0x8DFE appear
    usiSC_TEST_EVT1_OFF  : USINT := 241;   // Test Event 0x8DFE disappear
    usiSC_TEST_EVT2_ON   : USINT := 242;   // Test Event 0x8DFF appear
    usiSC_TEST_EVT2_OFF  : USINT := 243;   // Test Event 0x8DFF disappear

    // --- Event (Detailed Device Status index 37: 3 byte/entry; IODD không khai báo -> có thể trả 0x8011) ---
    uiIDX_EVT_LIST : UINT := 37;
    iEVT_COUNT     : INT  := 8;
    aEvtDef        : ARRAY[0..7] OF ST_IolEventDef := [
        (wCode := 16#4220, sName := 'TEMP', wsText := "Quá nhiệt thiết bị",                 eType := E_IolEvtType.WARNING),
        (wCode := 16#8CB0, sName := 'nEA',  wsText := "Cảnh báo: vật quá gần",              eType := E_IolEvtType.WARNING),
        (wCode := 16#8CB1, sName := 'fAr',  wsText := "Cảnh báo: vật quá xa",               eType := E_IolEvtType.WARNING),
        (wCode := 16#8CB4, sName := '+',    wsText := "Lỗi: cường độ phản xạ quá lớn",     eType := E_IolEvtType.ERROR),
        (wCode := 16#8CB5, sName := '-',    wsText := "Lỗi: không có vật / tín hiệu",       eType := E_IolEvtType.ERROR),
        (wCode := 16#8CA4, sName := 'ErP',  wsText := "Cảnh báo: sai lệch tính hợp lý",     eType := E_IolEvtType.WARNING),
        (wCode := 16#8DFE, sName := 'TEST1', wsText := "Sự kiện thử 1 (System Command 240)", eType := E_IolEvtType.NOTIFICATION),
        (wCode := 16#8DFF, sName := 'TEST2', wsText := "Sự kiện thử 2 (System Command 242)", eType := E_IolEvtType.NOTIFICATION)
    ];
END_VAR

