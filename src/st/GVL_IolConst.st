{attribute 'qualified_only'}
// Hằng số IO-Link Call qua PROFINET (spec PNO "IO-Link Integration for PROFINET")
VAR_GLOBAL CONSTANT
    // --- Khung IOL_CALL (record CAP) ---
    uiCAP_INDEX        : UINT  := 16#B400;   // record index CAP; CommFB.INDEX là INT -> truyền UINT_TO_INT (bit pattern giữ nguyên)
    usiEXT_FUNC_NUM    : USINT := 16#08;     // byte 0 khung IOL_CALL
    uiFI_INDEX         : UINT  := 16#FE4A;   // function index IOL_CALL (65098)
    usiCTRL_RELEASE    : USINT := 0;
    usiCTRL_WRITE      : USINT := 2;
    usiCTRL_READ       : USINT := 3;
    usiCTRL_ERROR      : USINT := 16#80;     // Control phản hồi lỗi - cần đối chiếu manual AL1100
    uiHDR_LEN          : UINT  := 8;         // header khung IOL_CALL
    uiMAX_DATA         : UINT  := 232;       // dữ liệu ISDU tối đa trong 1 IOL_CALL
    uiMAX_REC          : UINT  := 240;       // MLEN của RDREC = header + data

    // --- Vị trí AL1100 / thiết bị ---
    usiAL1_SLOT        : USINT := 1;         // submodule "IO-Link Master" (giả định, dự phòng slot 0/subslot 1)
    usiAL1_SUBSLOT_CAP : USINT := 1;
    usiPORT_O5D150     : USINT := 1;         // O5D150 cắm port X01 - đổi port tại đây

    // --- Thời gian / giới hạn ---
    tCALL_TIMEOUT      : TIME  := T#5S;      // tổng thời gian 1 request trong master
    tRETRY_DELAY       : TIME  := T#20MS;    // chờ giữa các lần RDREC khi master còn bận
    iMAX_RETRY         : INT   := 100;
    iQUEUE_SIZE        : INT   := 16;        // số client tối đa trên 1 master
    iMAX_PARAM         : INT   := 32;        // số tham số tối đa trong bảng của 1 device

    // --- Mã lỗi ISDU hay dùng ---
    uiERR_IDX_NA       : UINT  := 16#8011;   // index không tồn tại
    uiERR_SUBIDX_NA    : UINT  := 16#8012;
    uiERR_ACCESS       : UINT  := 16#8023;
    uiERR_RANGE        : UINT  := 16#8030;

    // --- STATUS nội bộ (không phải mã PNIO thật) ---
    dwSTAT_NOT_CONFIGURED : DWORD := 16#FFFF0001;  // FB_PnRecordAccess còn là khung, chưa có PN Controller
    dwSTAT_NO_TRANSPORT   : DWORD := 16#FFFF0002;  // master chưa được gán itfRec
END_VAR

