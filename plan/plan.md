TRẠNG THÁI: ĐÃ DUYỆT (người dùng duyệt 2026-11-07, chấp nhận các mặc định: Q8 khóa ghi bằng cờ GVL_HMI_IOL.xMaintEnable; Q7 gỡ 3 lib Turck IO-Link CALL; Q3/Q4 chưa có IP/station name/license PN → bước này chỉ dùng GVL_IO + FB_MockRecordAccess, cấu hình PROFINET làm sau; Q9 GVL_HMI_IOL riêng; O5D150 ở port 1)
Nền tảng: CODESYS V3.5 SP21 P1 — project D:\Codesys_Demo\TBEN_L5_PLC11.project

# Plan: IO-Link Call qua PROFINET (ifm AL1100) + kiến trúc device theo IODD (device đầu tiên: ifm O5D150)

Ngày lập: 2026-11-07. Chế độ: **thêm chức năng** vào project đang có. Plan chỉ đọc, chưa ghi gì vào project.

## 0. Ngữ cảnh đã kiểm tra (nguồn)

| Hạng mục                                | Kết quả                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | Nguồn                                                                                                                                          |
| --------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| Project đang mở                         | `D:\Codesys_Demo\TBEN_L5_PLC11.project` (dirty = có thay đổi chưa save), active app `TBEN_L5_PLC_11/Plc Logic/Application`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  | `codesys_status`                                                                                                                               |
| Cây thiết bị hiện tại                   | `TBEN_L5_PLC_11` → `Plc Logic/Application`, `LEDs`, `Local_IO` (DXP, Diagnostics, VAUX_control, Module_status), `COM0`, `COM1`, `CANbus`. **Chưa có Ethernet adapter, chưa có PROFINET IO Controller, chưa có AL1100.**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     | `codesys_list_objects`                                                                                                                         |
| Đối tượng Application                   | PLC_PRG, E_SeqMode, GVL_IO, GVL_HMI, FB_OutSeq, Visu_Main, Visualization Manager/WebVisu, Task Configuration (MainTask→PLC_PRG, VISU_TASK→VisuElems.Visu_Prg)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               | `codesys_list_objects`                                                                                                                         |
| Đọc nội dung POU/GVL                    | **Không đọc được**: bridge trả "closed the connection without an answer" cho `codesys_read_object` và `codesys_export_xml` (list vẫn chạy). Đã dừng sau 5 lần thử theo quy tắc MCP. → Quy ước đặt tên bên dưới là giả định, agent code phải đọc lại GVL_IO/GVL_HMI/PLC_PRG trước khi ghi.                                                                                                                                                                                                                                                                                                                                                                                                                   | bridge                                                                                                                                         |
| TBEN cho phép PN Controller             | Device description TBEN-Lx-PLC-1x (3.5.21.10): module `LocalEthernet` cho phép con là **PN Controller** `deviceType=80, deviceId="0000 0002", version="3.5.16.20"` (MaxNumber 1). Device repo có PN Controller 3.5.16.20 (và 3.5.15.40 … 4.8.0.0).                                                                                                                                                                                                                                                                                                                                                                                                                                                          | `C:\ProgramData\CODESYS\Devices\4096\10CD 0101\3.5.21.10\device.xml` dòng 2282–2306; `C:\ProgramData\CODESYS\Devices\80\0000 0002\`            |
| Thư viện PN Controller kéo theo         | `IoDrvProfinet` (FB instance `ProfinetController`), `CommFB`, `ProfinetCommon`                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              | `...\Devices\80\0000 0002\3.5.16.20\device.xml` dòng 1126–1133                                                                                 |
| FB đọc/ghi record                       | **`CommFB.RDREC` / `CommFB.WRREC`** (chuẩn PNO IEC 61131-3 Comm FB). ID lấy bằng `CommFB.SUBSLOT_ID(EN:=TRUE, ID:=<PN_Device>.DeviceID, SLOT:=x, SUBSLOT:=y)` → `DWORD`; hoặc `CommFB.CREATE_ID(ADDR:=…)`; hằng `CommFB.Constants.INVALID_ID`. RDREC: in `REQ, ID, INDEX(INT), MLEN(INT), RECORD`; out `VALID, BUSY, ERROR, STATUS(DWORD), LEN`. WRREC: out `DONE, BUSY, ERROR, STATUS`. `ProfinetCommon.SUBSLOT_ID` đã DEPRECATED.                                                                                                                                                                                                                                                                         | browsercache `CommFB 3.5.18.0` và `IoDrvProfinet 4.2.2.0` (Managed Libraries)                                                                  |
| GSDML AL1100                            | Đã cài: `GSDML-V2.34-ifm-AL1100-20181105.xml`, DAP `DIM 1` (ModuleIdent 0x10100000), MinDeviceInterval=8 (=250 µs), Slot 0 = DAP (subslot 1, 0x8000 interface, 0x8001/0x8002 port Ethernet). Slot 1 = module cố định `IN_OUT_MODULE_IO-Link 16I/16O`: **subslot 1 = submodule ảo "IO-Link Master"** (API 19969 = 0x4E01, record 301 Usecase), **subslot 2..5 = Port 1..4** (chọn submodule "IO-Link 1I…32I/32O", "DI", "DO", "INACTIVATE"; mỗi port có record 0xB100 Port parameters 12 byte, record 300 Fail-safe). Input mỗi port kèm byte **PQI** (bit0 DI4, bit1 DI2, bit2 NP, bit3 SV, bit4 DA, bit5 DC, bit6 DE, bit7 PQ). GSDML **không khai báo** record 0xB400 (bình thường – CAP là record động). | `C:\ProgramData\CODESYS\Devices\81\GSDML-0136-AC52-V2.34-ifm-AL1100-20181105 - DIM 1\GSDML-V2.34-ifm-AL1100-20181105.xml` dòng 26–132, 859–870 |
| Lib Turck IO-Link trong Library Manager | IO-Link CALL Base 1.1.0.0, IO-Link CALL Local IO 1.1.0.0, IO-Link CALL Modbus TCP 1.0.1.0; ngoài ra project còn nạp `commfb base 1.0.1.0`, `commfb local io 1.1.0.0`, `commfb modbus tcp 1.0.1.0` (Turck)                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   | `codesys_status` (danh sách lib đang mở)                                                                                                       |
| O5D150                                  | Trang ifm/ioddfinder không tải được nội dung (JS/HTTP 410/503). **Mọi thông số O5D150 trong plan là giả định từ kiến thức chung, phải đối chiếu IODD thật.**                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                | WebFetch thất bại                                                                                                                              |

## 1. Tóm tắt yêu cầu

- Thêm PROFINET IO Controller vào TBEN-L5-PLC-11, cấu hình ifm AL1100 (4 cổng IO-Link) làm IO-Device.
- Viết bộ FB IO-Link Call dùng chung theo "IO-Link Integration for PROFINET" (PNO): ghi khung IOL_CALL bằng `CommFB.WRREC` vào record **0xB400 (CAP)**, đọc phản hồi bằng `CommFB.RDREC`, có Execute/Busy/Done/Error, timeout, giải mã lỗi, **khóa/hàng đợi FIFO 1 request/master**.
- Kiến trúc device theo IODD: mỗi model một `FB_Dev_<Model>` (kế thừa `FB_IolDevBase`) + DUT process data + bảng tham số hằng (index/subindex/kiểu/scale/đơn vị/min-max/RW) + GVL_HMI + visu template riêng. Device đầu tiên: **ifm O5D150 ở Port 1 (X01)** – port là hằng số dễ đổi.
- Test trước trên CODESYS Simulation bằng **mock record transport**, sau đó test trên TBEN + AL1100 thật.

## 2. Bảng I/O

Không có I/O số/analog vật lý mới trên Local_IO. I/O mới là **process data PROFINET của AL1100** (tạo biến mới qua I/O mapping của submodule, kiểu "Create new variable" → khuyến nghị map vào biến có sẵn trong `GVL_IO` để force được trên Simulation).

| Biến (GVL_IO)                   | Kênh I/O mapping                                                                 | Kiểu                  | Mô tả                                                                            | Ghi chú                                                                                                          |
| ------------------------------- | -------------------------------------------------------------------------------- | --------------------- | -------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------- |
| `GVL_IO.abAL1_P1_In`            | AL1100 / Slot 1 / Subslot 2 (Port 1) submodule **"IO-Link 2I"** → `Input_Data_2` | `ARRAY[0..1] OF BYTE` | PDin O5D150 (2 byte, big-endian)                                                 | Độ dài 2 byte = **giả định**, xem mục 13. Nếu IODD cho PDin 4 byte → đổi submodule "IO-Link 4I" và mảng `[0..3]` |
| `GVL_IO.bAL1_P1_PQI`            | cùng submodule → `PQI`                                                           | `BYTE`                | Port Qualifier: bit7 PQ (PD hợp lệ), bit6 DE, bit5 DC, bit4 DA, bit3 SV, bit2 NP | Chỉ dùng PDin khi PQ=1                                                                                           |
| `GVL_IO.abAL1_P2_In` … `P4_In`  | Subslot 3..5                                                                     | `ARRAY OF BYTE`       | Placeholder port 2..4                                                            | Submodule hiện để **"INACTIVATE"** cho tới khi biết thiết bị                                                     |
| `GVL_IO.bAL1_P2_PQI` … `P4_PQI` | Subslot 3..5                                                                     | `BYTE`                | Placeholder                                                                      |                                                                                                                  |
| (không dùng)                    | Port DO/PDout                                                                    | –                     | O5D150 không có PDout (giả định)                                                 |                                                                                                                  |

Quy định: **chỉ** `GVL_IO` được map I/O; FB device đọc từ `GVL_IO` qua VAR_INPUT (không đọc thẳng `%IB`). Trên Simulation các biến này được Write/Force.

Địa chỉ `%IB…` sẽ do CODESYS cấp tự động sau khi thêm submodule — agent code ghi lại vào bảng này sau bước cấu hình phần cứng.

## 3. Kiến trúc chương trình

### 3.1 Cấu hình phần cứng (cây thiết bị) cần làm

```
TBEN_L5_PLC_11
 └─ Ethernet (LocalEthernet, interface = cổng của TBEN, IP 192.168.2.3/24)   [MỚI]
     └─ PN_Controller (PROFINET IO Controller, version 3.5.16.20)            [MỚI]
         │   IP range: ví dụ 192.168.2.100–.150, default gateway, Send clock 1 ms
         └─ AL1100 (ifm, GSDML V2.34 DAP "DIM 1")                            [MỚI]
             │   Station name: "al1100-1" (phải trùng tên đặt trên thiết bị qua DCP)
             │   IP: 192.168.2.10 (đề xuất – chờ xác nhận)
             │   Reduction ratio → IO cycle 4..8 ms (≥ 250 µs MinDeviceInterval)
             └─ Slot 1: IO-Link 16I/16O module (cố định)
                 ├─ Subslot 1: IO-Link Master (ảo)  ← nhận IOL_CALL (giả định, xem 6.3)
                 ├─ Subslot 2: Port 1 = "IO-Link 2I"   (O5D150)
                 ├─ Subslot 3: Port 2 = "INACTIVATE"   (placeholder)
                 ├─ Subslot 4: Port 3 = "INACTIVATE"   (placeholder)
                 └─ Subslot 5: Port 4 = "INACTIVATE"   (placeholder)
```

- Port parameters (record 0xB100) Port 1: PortMode = IO-Link (giá trị 11 trong GSDML), Cycle time = 0 (as fast as possible), **Validation/IntegrationLevel = 0 (no check)** lúc commissioning; sau khi có Vendor ID 310 (0x0136) và Device ID O5D150 thì có thể bật kiểm tra type.
- Bus cycle task của PN_Controller = **MainTask** (PLC settings → Bus cycle task). Các CommFB phải được gọi trong cùng task này.
- Nhớ (memory "codesys-script-new-project"): nếu thêm device bằng script → **save, close, reopen** project trước khi build để tránh lỗi `Tparam_ unknown type`.
- License: PN Controller SL trên TBEN cần license (nếu không có → chạy demo giới hạn thời gian). **Phải xác nhận với Turck/CODESYS store** (mục 13).

### 3.2 Thay đổi Library Manager (Application)

| Hành động                            | Thư viện                                                                        | Lý do                                                                                                                                                                                                                                                                                                |
| ------------------------------------ | ------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Giữ (tự thêm khi thêm PN Controller) | `CommFB` (3S), `ProfinetCommon`, `IoDrvProfinet`                                | RDREC/WRREC/SUBSLOT_ID                                                                                                                                                                                                                                                                               |
| Giữ                                  | `Standard`, `Util` (đã có)                                                      | TON, R_TRIG, chuỗi                                                                                                                                                                                                                                                                                   |
| **Gỡ**                               | `IO-Link CALL Base`, `IO-Link CALL Local IO`, `IO-Link CALL Modbus TCP` (Turck) | Chỉ dành cho IO-Link master Turck; Local IO và Modbus TCP trùng tên `IOL_CALL` → nguy cơ ambiguous. TBEN-L5-PLC-11 không có cổng IO-Link local.                                                                                                                                                      |
| **Kiểm tra trước khi gỡ/giữ**        | Turck `commfb base / commfb local io / commfb modbus tcp`                       | Có thể là dependency của lib Turck ở trên hoặc của device description; nếu trùng tên POU với `CommFB` (3S) (vd RDREC/WRREC) thì **luôn gọi đủ namespace `CommFB.RDREC`**, và đặt `{attribute 'qualified_only'}` cho lib bị trùng (Library Manager → Properties → Namespace). Nếu không ai dùng → gỡ. |
| Không thêm                           | HTTP client                                                                     | Không có trong repo, không cần cho hướng PROFINET                                                                                                                                                                                                                                                    |

Quy tắc code: **mọi lời gọi thư viện PN viết đầy đủ namespace** `CommFB.RDREC`, `CommFB.WRREC`, `CommFB.SUBSLOT_ID`, `CommFB.Constants.INVALID_ID`.

### 3.3 Đối tượng cần tạo (đường dẫn dưới `TBEN_L5_PLC_11/Plc Logic/Application/`)

Đề xuất gom vào folder `IOLink/` (Common, Devices/O5D150, Visu). Tất cả ST.

| Đối tượng                                                                                                                          | Loại                                   | Vai trò                                                                                           |
| ---------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------- |
| `IOLink/Common/E_IolCallState`                                                                                                     | DUT ENUM                               | Trạng thái state machine master                                                                   |
| `IOLink/Common/E_IolService`                                                                                                       | DUT ENUM                               | READ=3, WRITE=2 (giá trị Control)                                                                 |
| `IOLink/Common/E_IolDataType`                                                                                                      | DUT ENUM                               | BOOL, UINT8/16/32, INT8/16/32, FLOAT32, STRING, OCTET                                             |
| `IOLink/Common/E_IolAccess`                                                                                                        | DUT ENUM                               | RO, WO, RW                                                                                        |
| `IOLink/Common/E_IolErrSource`                                                                                                     | DUT ENUM                               | NONE, PNIO (RDREC/WRREC STATUS), IOL_MASTER, IOL_DEVICE, TIMEOUT, PARAM, LOCK, FRAME              |
| `IOLink/Common/ST_IolRequest`                                                                                                      | DUT STRUCT                             | port, index, subindex, service, data, len                                                         |
| `IOLink/Common/ST_IolResult`                                                                                                       | DUT STRUCT                             | data, len, error, mã lỗi, text                                                                    |
| `IOLink/Common/ST_IolParamDef`                                                                                                     | DUT STRUCT                             | định nghĩa 1 tham số từ IODD                                                                      |
| `IOLink/Common/ST_IolParamVal`                                                                                                     | DUT STRUCT                             | giá trị runtime + trạng thái đọc/ghi 1 tham số (cho HMI)                                          |
| `IOLink/Common/ST_IolPortDiag`                                                                                                     | DUT STRUCT                             | PQI giải mã, device status (index 36)                                                             |
| `IOLink/Common/ITF_IolRecordAccess`                                                                                                | INTERFACE                              | Trừu tượng hóa WRREC/RDREC (thật / mock)                                                          |
| `IOLink/Common/FB_PnRecordAccess`                                                                                                  | FB IMPLEMENTS ITF                      | Bọc `CommFB.WRREC`/`CommFB.RDREC`                                                                 |
| `IOLink/Common/FB_MockRecordAccess`                                                                                                | FB IMPLEMENTS ITF                      | Giả lập AL1100 + device (Simulation)                                                              |
| `IOLink/Common/FB_IolMaster`                                                                                                       | FB                                     | 1 instance / AL1100: khóa, hàng đợi FIFO, state machine IOL_CALL                                  |
| `IOLink/Common/FB_IolCall`                                                                                                         | FB                                     | Client handshake Execute/Busy/Done/Error, gắn vào 1 master                                        |
| `IOLink/Common/FB_IolDevBase`                                                                                                      | FB (ABSTRACT)                          | Lớp cơ sở device: Read/Write theo ParamDef, ReadAll/WriteAll, ReadIdent, PQI                      |
| `IOLink/Common/F_IolGetU16BE`, `F_IolSetU16BE`, `F_IolGetU32BE`, `F_IolSetU32BE`, `F_IolGetR32BE`, `F_IolSetR32BE`, `F_IolGetBits` | FUNCTION                               | Đóng/mở gói big-endian (TBEN là ARM little-endian)                                                |
| `IOLink/Common/F_IolErrText`                                                                                                       | FUNCTION → `WSTRING(80)`               | Mã lỗi → chuỗi hiển thị                                                                           |
| `IOLink/Common/GVL_IolConst`                                                                                                       | GVL CONSTANT, `qualified_only`         | CAP, FI_Index, slot/subslot, timeout, mã lỗi                                                      |
| `IOLink/Common/GVL_IolSys`                                                                                                         | GVL, `qualified_only`                  | `fbAL1: FB_IolMaster`, `fbPnAL1: FB_PnRecordAccess`, `fbMockAL1: FB_MockRecordAccess`, `xSimMode` |
| `IOLink/Devices/O5D150/ST_O5D150_PdIn`                                                                                             | DUT STRUCT                             | PDin đã giải mã                                                                                   |
| `IOLink/Devices/O5D150/E_O5D150_Param`                                                                                             | DUT ENUM                               | Chỉ số tham số trong bảng (không phải IOL index)                                                  |
| `IOLink/Devices/O5D150/GVL_O5D150_Def`                                                                                             | GVL CONSTANT, `qualified_only`         | `aParamDef: ARRAY[E_O5D150_Param] OF ST_IolParamDef` – sinh từ IODD                               |
| `IOLink/Devices/O5D150/FB_Dev_O5D150`                                                                                              | FB EXTENDS FB_IolDevBase               | Giải mã PDin, tham số riêng, teach                                                                |
| `IOLink/PRG_IOLink`                                                                                                                | PROGRAM                                | Gọi master + mọi device, cầu nối HMI                                                              |
| `GVL_HMI` (có sẵn) – **thêm** khối biến IO-Link, hoặc tạo `GVL_HMI_IOL`                                                            | GVL                                    | Biến giao tiếp visu (xem mục 8)                                                                   |
| `IOLink/Visu/VT_IolGeneric`                                                                                                        | Visualization (template, có Interface) | ISDU raw read/write + chẩn đoán, dùng cho mọi device                                              |
| `IOLink/Visu/VT_Dev_O5D150`                                                                                                        | Visualization (template)               | Màn hình riêng O5D150                                                                             |
| `IOLink/Visu/Visu_IOLink`                                                                                                          | Visualization                          | Tổng quan 4 port, Frame chứa template theo port                                                   |

### 3.4 Task configuration

| Task               | Chu kỳ                                                                            | Ưu tiên | POU                                 | Ghi chú                                       |
| ------------------ | --------------------------------------------------------------------------------- | ------- | ----------------------------------- | --------------------------------------------- |
| MainTask (có sẵn)  | **giữ nguyên chu kỳ hiện có** – khuyến nghị ≤ 10 ms (chưa đọc được, cần xác nhận) | giữ     | `PLC_PRG` → gọi `PRG_IOLink` ở cuối | Đồng thời là bus cycle task của PN_Controller |
| VISU_TASK (có sẵn) | giữ                                                                               | giữ     | VisuElems.Visu_Prg                  | Không gọi FB IO-Link trong VISU_TASK          |

Không tạo task riêng cho IO-Link: CommFB phải chạy cùng ngữ cảnh bus cycle; khối lượng IOL_CALL nhỏ.

### 3.5 Call tree

```
MainTask
 └─ PLC_PRG  (logic cũ giữ nguyên)
     └─ PRG_IOLink()
         ├─ GVL_IolSys.fbAL1(itfRec := (xSimMode ? fbMockAL1 : fbPnAL1), ...)   // master: state machine IOL_CALL
         │    └─ itfRec.Write(...) / itfRec.Read(...)  → CommFB.WRREC / CommFB.RDREC  (hoặc mock)
         ├─ fbDevP1 : FB_Dev_O5D150  (refMaster := GVL_IolSys.fbAL1, usiPort := GVL_IolConst.usiPORT_O5D150, abPdIn := GVL_IO.abAL1_P1_In, bPQI := GVL_IO.bAL1_P1_PQI)
         │    └─ FB_IolDevBase.fbCall : FB_IolCall  → đăng ký vào hàng đợi fbAL1
         ├─ (placeholder) fbDevP2..P4
         └─ ánh xạ GVL_HMI_IOL <-> device (chỉ 1 chỗ ghi mỗi biến)
```

## 4. Thiết kế từng POU

### 4.1 `GVL_IolConst` (VAR_GLOBAL CONSTANT, `{attribute 'qualified_only'}`)

| Hằng                                | Giá trị             | Ghi chú                                                                                                                                                                                              |
| ----------------------------------- | ------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `uiCAP_INDEX`                       | `16#B400` (46080)   | Record index CAP. **Lưu ý `CommFB.RDREC.INDEX` là INT** → truyền `WORD_TO_INT(16#B400)` (= −19456, bit pattern đúng) – ví dụ trong lib cũng làm vậy với `TO_INT(16#AFF0)`. Phải kiểm bằng test thật. |
| `usiEXT_FUNC_NUM`                   | `16#08`             | Byte 0 khung IOL_CALL                                                                                                                                                                                |
| `uiFI_INDEX`                        | `65098` (`16#FE4A`) | IOL_CALL function index                                                                                                                                                                              |
| `usiCTRL_RELEASE / WRITE / READ`    | `0 / 2 / 3`         | Control request                                                                                                                                                                                      |
| `usiCTRL_ERROR`                     | `16#80`             | Control phản hồi lỗi (cần kiểm, mục 6.3)                                                                                                                                                             |
| `usiAL1_SLOT`, `usiAL1_SUBSLOT_CAP` | `1`, `1`            | Submodule "IO-Link Master" nhận CAP (giả định; phương án dự phòng slot 0/subslot 1)                                                                                                                  |
| `usiPORT_O5D150`                    | `1`                 | **Port X01 – hằng số đổi ở đây**                                                                                                                                                                     |
| `uiHDR_LEN`                         | `8`                 | Độ dài header IOL_CALL                                                                                                                                                                               |
| `uiMAX_DATA`                        | `232`               | ISDU data tối đa                                                                                                                                                                                     |
| `uiMAX_REC`                         | `240`               | MLEN RDREC                                                                                                                                                                                           |
| `tCALL_TIMEOUT`                     | `T#5S`              | Timeout tổng 1 request (cần ≥ thời gian ISDU dài, vd system command teach)                                                                                                                           |
| `tRETRY_DELAY`                      | `T#20MS`            | Chờ giữa các lần RDREC khi master báo bận                                                                                                                                                            |
| `iMAX_RETRY`                        | `100`               |                                                                                                                                                                                                      |
| `iQUEUE_SIZE`                       | `16`                | Số client tối đa / master                                                                                                                                                                            |

### 4.2 Khung record 0xB400 (byte layout, big-endian)

**Request (WRREC, INDEX=0xB400, LEN = 8 + n):**

| Byte     | Trường                | Kiểu              | Giá trị                               |
| -------- | --------------------- | ----------------- | ------------------------------------- |
| 0        | Extended_Function_Num | UINT8             | 0x08                                  |
| 1        | Port (EntityPort)     | UINT8             | 0 = master, 1..4 = port               |
| 2..3     | FI_Index              | UINT16 BE         | 0xFE4A (65098)                        |
| 4        | Control               | UINT8             | 0x03 Read / 0x02 Write / 0x00 Release |
| 5..6     | IOL_Index             | UINT16 BE         | 0..65535                              |
| 7        | IOL_Subindex          | UINT8             | 0 = toàn bộ index                     |
| 8..8+n−1 | Data                  | OCTET[n], n ≤ 232 | chỉ khi Write                         |

**Response (RDREC, INDEX=0xB400, MLEN=240):**

| Byte      | Trường                                            | Ghi chú                                           |
| --------- | ------------------------------------------------- | ------------------------------------------------- |
| 0         | 0x08                                              | kiểm tra, sai → lỗi FRAME                         |
| 1         | Port                                              | phải bằng port đã gửi                             |
| 2..3      | 0xFE4A                                            |                                                   |
| 4         | Control                                           | = control đã gửi (0x02/0x03) → OK; **0x80 → lỗi** |
| 5..6      | IOL_Index                                         | echo (kiểm tra)                                   |
| 7         | Subindex                                          | echo                                              |
| 8..       | Data (Read)                                       | độ dài = `RDREC.LEN − 8`                          |
| Lỗi: 5..6 | IOL_M_ErrorCode (UINT16)                          | lỗi master (0x7xxx/0x8xxx)                        |
| Lỗi: 7..8 | IOL_D_ErrorCode (ErrorCode 0x80 + AdditionalCode) | lỗi ISDU device                                   |

Vị trí byte trường lỗi (5..8) và giá trị Control phản hồi là **theo hiểu biết spec PNO / Siemens IO_LINK_DEVICE – chưa đối chiếu tài liệu gốc** → mục 13 (cần spec "IO-Link Integration for PROFINET" Order 2.832 hoặc manual AL1100). Code phải tách phần parse vào 1 method `ParseResponse` để sửa một chỗ.

Mã lỗi device (IO-Link spec, ISDU ErrorType – tin cậy): 0x8000 Application error, 0x8011 Index not available, 0x8012 Subindex not available, 0x8020 Service temporarily not available, 0x8021 …local control, 0x8022 …device control, 0x8023 Access denied, 0x8030 Value out of range, 0x8031 above limit, 0x8032 below limit, 0x8033 Length overrun, 0x8034 Length underrun, 0x8035 Function not available, 0x8036 Function temporarily unavailable, 0x8040 Invalid parameter set, 0x8041 Inconsistent parameter set, 0x8082 Application not ready.

Mã lỗi master (PNO, **cần kiểm**): 0x7000 IOL_CALL conflict, 0x7001 Wrong IOL_CALL, 0x7002 Port blocked, 0x8000 Timeout, 0x8001 Invalid port, 0x8002 Invalid port mode, 0x8003 Invalid length, 0x8004 Communication error …

Mã lỗi PNIO (STATUS DWORD của RDREC/WRREC = 4 byte ErrorCode/ErrorDecode/ErrorCode1/ErrorCode2, vd `DE 80 B0 xx` invalid index, `DE 80 B5 xx` state conflict, `DE 80 C3 xx` resource busy, `DE 80 B2 xx` invalid slot/subslot): B5/C3 → coi là "master bận" → retry; còn lại → lỗi PNIO. CommFB còn có `CommFB.ErrorCode.TIMEOUT` (nội bộ lib).

### 4.3 `ITF_IolRecordAccess` (INTERFACE)

```
METHOD Write : BOOL     // TRUE khi đã xong (DONE hoặc ERROR) – gọi mỗi chu kỳ khi bReq
  VAR_INPUT xReq: BOOL; dwId: DWORD; iIndex: INT; iLen: INT; pData: POINTER TO BYTE; END_VAR
  VAR_OUTPUT xDone, xBusy, xError: BOOL; dwStatus: DWORD; END_VAR
METHOD Read : BOOL
  VAR_INPUT xReq: BOOL; dwId: DWORD; iIndex: INT; iMLen: INT; pData: POINTER TO BYTE; END_VAR
  VAR_OUTPUT xValid, xBusy, xError: BOOL; dwStatus: DWORD; iLen: INT; END_VAR
PROPERTY dwId : DWORD (GET)   // ID submodule CAP
```

- `FB_PnRecordAccess`: VAR `fbWr: CommFB.WRREC; fbRd: CommFB.RDREC; dwId: DWORD;` Input `usiSlot, usiSubslot`, VAR_IN_OUT hoặc input `dwDeviceId` = `<tên device AL1100>.DeviceID` (tên instance tự sinh khi thêm AL1100 – agent code kiểm tra đúng tên, vd `AL1100.DeviceID`). `dwId := CommFB.SUBSLOT_ID(EN:=TRUE, ID:=dwDeviceId, SLOT:=usiSlot, SUBSLOT:=usiSubslot)`; nếu `= CommFB.Constants.INVALID_ID` → lỗi cấu hình. **Kiểu chân RECORD (POINTER hay ANY / ARRAY)** phải xem trong Library Manager → `CommFB.RDREC` (browsercache chỉ cho thấy tên chân). Nếu là ANY → khai báo buffer `abRec: ARRAY[0..239] OF BYTE` cục bộ và copy bằng `MEMCPY`/`SysMemCpy`.
- `FB_MockRecordAccess`: giả lập độ trễ (`tDelayWr`, `tDelayRd`, mặc định 30 ms), bảng `aMockParam: ARRAY[0..31] OF ST_MockParam` (port, index, subindex, data, len, access), cờ chèn lỗi `xInjPnioErr, xInjBusyCount (số lần trả B5), xInjDevErr (uiDevErr), xInjNoResponse (để test timeout), xInjBadFrame`. Write lưu request; Read trả response theo layout 4.2. Giá trị mặc định nạp bảng: index 16 "ifm electronic gmbh", 18 "O5D150", 21 "SIM0001", 36 = 0, + tham số O5D150 trong `GVL_O5D150_Def`.

### 4.4 `FB_IolMaster` (1 instance cho mỗi AL1100)

```
VAR_INPUT
  itfRec      : ITF_IolRecordAccess;   // thật hoặc mock
  xEnable     : BOOL := TRUE;
  tTimeout    : TIME := GVL_IolConst.tCALL_TIMEOUT;
  xReset      : BOOL;                  // reset lỗi kẹt / xóa hàng đợi
END_VAR
VAR_OUTPUT
  eState      : E_IolCallState;
  xBusy       : BOOL;
  usiActiveClient : USINT;             // 0 = rảnh
  uiQueueCount: UINT;
  udiCallCount, udiErrCount : UDINT;   // thống kê
END_VAR
VAR
  aQueue : ARRAY[0..GVL_IolConst.iQUEUE_SIZE-1] OF USINT; // FIFO client handle
  iHead, iTail : INT;
  aReq   : ARRAY[1..GVL_IolConst.iQUEUE_SIZE] OF ST_IolRequest; // slot request mỗi client
  aRes   : ARRAY[1..GVL_IolConst.iQUEUE_SIZE] OF ST_IolResult;
  axReqPending, axResReady : ARRAY[1..GVL_IolConst.iQUEUE_SIZE] OF BOOL;
  abTx, abRx : ARRAY[0..239] OF BYTE;
  tonTimeout, tonRetry : TON;          // instance riêng
  iRetry : INT;
  usiNextHandle : USINT;
END_VAR
METHOD Register : USINT          // client gọi 1 lần khi init → handle 1..16 (0 = hết chỗ)
METHOD Submit   : BOOL           // (hHandle, stReq) → đưa vào FIFO; FALSE nếu đã pending
METHOD Poll     : BOOL           // (hHandle, VAR_IN_OUT stRes) → TRUE khi có kết quả, xóa cờ
METHOD Cancel                    // (hHandle) – client bỏ request (Execute rớt trước khi Done)
METHOD ParseResponse : BOOL      // tách riêng để sửa layout lỗi một chỗ
```

Khóa: chỉ state `IDLE` mới lấy client tiếp theo từ FIFO → tại 1 thời điểm chỉ một record WRREC/RDREC đang chạy trên master. Hàng đợi FIFO bảo đảm công bằng giữa các device. Không dùng lock dạng "ai gọi trước trong chu kỳ thắng".

### 4.5 `FB_IolCall` (client, handshake chuẩn PLCopen-style)

```
VAR_INPUT
  xExecute   : BOOL;                 // sườn lên bắt đầu
  usiPort    : USINT;                // 1..4 (0 = master)
  eService   : E_IolService;         // READ / WRITE
  uiIndex    : UINT;
  usiSubindex: USINT;
  pData      : POINTER TO BYTE;      // buffer ghi (WRITE) / nhận (READ)
  uiDataLen  : UINT;                 // WRITE: số byte ghi; READ: kích thước buffer
END_VAR
VAR_IN_OUT
  refMaster  : FB_IolMaster;
END_VAR
VAR_OUTPUT
  xDone, xBusy, xError : BOOL;
  uiLenRead  : UINT;
  eErrSource : E_IolErrSource;
  dwPnioStatus : DWORD;
  uiIolMasterErr : UINT;            // IOL_M_ErrorCode
  uiIolDevErr    : UINT;            // IOL_D (0x80xx)
  wsErrText  : WSTRING(80);
END_VAR
VAR
  rtExec : R_TRIG; hHandle : USINT; eStep : (IDLE, WAIT_QUEUE, DONE, ERR);
END_VAR
```

Quy tắc: kiểm tham số trước khi Submit (port 0..4, uiDataLen ≤ 232, pData <> 0) → lỗi PARAM. `xDone/xError` giữ cho tới khi `xExecute = FALSE` (tối thiểu 1 chu kỳ nếu Execute đã rớt). Execute rớt khi đang Busy → vẫn chạy tới hết, kết quả hiện 1 chu kỳ (giống PLCopen). Timeout tính trong master (bao trùm cả thời gian chờ hàng đợi thì dùng thêm TON riêng trong client = 2 × tCALL_TIMEOUT).

### 4.6 `FB_IolDevBase` (ABSTRACT) – nền cho mọi device

```
VAR_INPUT
  usiPort  : USINT;
  pPdIn    : POINTER TO BYTE; uiPdInLen : UINT;   // từ GVL_IO
  bPQI     : BYTE;
  xCmdReadAll, xCmdWriteAll, xCmdReadIdent, xCmdReadOne, xCmdWriteOne : BOOL;  // sườn lên
  iParamSel: INT;                                  // tham số chọn cho ReadOne/WriteOne
END_VAR
VAR_IN_OUT refMaster : FB_IolMaster; END_VAR
VAR_OUTPUT
  stDiag   : ST_IolPortDiag;    // PQ, DE, DC, DA, Device status (index 36)
  xPdValid : BOOL;              // = PQ AND DA
  xBusy, xError : BOOL; wsLastErr : WSTRING(80);
  stIdent  : ST_IolIdent;       // index 16,17,18,19,20,21,22,23,24 (STRING(64))
END_VAR
VAR
  fbCall : FB_IolCall;          // instance riêng mỗi device
  abBuf  : ARRAY[0..231] OF BYTE;
  eSeq   : E_IolDevSeq;         // IDLE, READ_IDENT, READ_PARAM, WRITE_PARAM, NEXT, DONE, ERR
  iCur   : INT;
END_VAR
METHOD ABSTRACT DecodePdIn          // device tự giải mã PDin
METHOD ABSTRACT GetParamDef : POINTER TO ST_IolParamDef   (iParam) / ParamCount : INT
METHOD PROTECTED DecodeValue (def, buf, len) → cập nhật ST_IolParamVal (raw, rEng)
METHOD PROTECTED EncodeValue (def, rEng hoặc raw) → buf, len; kiểm Min/Max → lỗi PARAM trước khi gửi
PROPERTY aVal : REFERENCE/POINTER tới mảng ST_IolParamVal của lớp con
```

`ReadAll`: lặp mọi tham số có Access ≠ WO; `WriteAll`: chỉ tham số RW và có cờ `xDirty` từ HMI; sau WriteAll tự `ReadAll` lại để xác nhận. Dừng ở lỗi đầu tiên hoặc tiếp tục (cờ `xContinueOnError`, mặc định TRUE, lỗi từng tham số lưu ở `ST_IolParamVal.uiErr`).

### 4.7 DUT chung

```
ST_IolParamDef : STRUCT
  sName      : STRING(32);    wsText : WSTRING(40);   // tên IODD + nhãn HMI tiếng Việt
  uiIndex    : UINT;  usiSubindex : USINT;
  eType      : E_IolDataType; usiBitOffset : USINT; usiBitLen : USINT;   // cho record con
  eAccess    : E_IolAccess;
  rGradient  : REAL := 1.0;   rOffset : REAL := 0.0;  // Eng = raw*Gradient + Offset (IODD)
  rMin, rMax : REAL;          // theo IODD (đơn vị kỹ thuật)
  sUnit      : STRING(8);
  diDefault  : DINT;
  xInReadAll : BOOL := TRUE;
END_STRUCT

ST_IolParamVal : STRUCT
  diRaw : DINT; rEng : REAL; sStr : STRING(64);
  rSetEng : REAL; xDirty : BOOL;     // HMI nhập
  xValid : BOOL; uiErr : UINT; dtLastRead : DT;
END_STRUCT
```

### 4.8 `FB_Dev_O5D150 EXTENDS FB_IolDevBase` (device đầu tiên)

- Output thêm: `stPd : ST_O5D150_PdIn`, `aVal : ARRAY[E_O5D150_Param] OF ST_IolParamVal`.
- `xCmdTeachSP1`, `xCmdTeachSP2`, `xCmdFactoryReset` (sườn lên, cần xác nhận HMI 2 bước) → ghi index 2 SystemCommand.
- `DecodePdIn`: theo layout trong `GVL_O5D150_Def` (bit offset/len), chỉ khi `xPdValid`; nếu không hợp lệ → `stPd.xValid := FALSE`, giữ giá trị cũ, không ghi 0.

`ST_O5D150_PdIn` (giả định làm việc – **chưa xác minh**):

| Trường      | Kiểu | Nguồn bit (PDin 16 bit BE, bit 15 = MSB byte 0)                     | Ghi chú                             |
| ----------- | ---- | ------------------------------------------------------------------- | ----------------------------------- |
| `xOut1`     | BOOL | bit 0                                                               | trạng thái switching OUT1           |
| `xOut2`     | BOOL | bit 1                                                               | OUT2                                |
| `uiDistRaw` | UINT | bit 4..15 (12 bit) **hoặc** 2..15                                   | **IODD quyết định**                 |
| `rDist_mm`  | REAL | `uiDistRaw * rGradient + rOffset`                                   | đơn vị mm (giả định 1 digit = 1 mm) |
| `xNoSignal` | BOOL | giá trị đặc biệt IODD (vd raw 0 / max = "no object / out of range") | IODD SingleValue                    |
| `xValid`    | BOOL | PQ AND DA AND NOT xNoSignal                                         |                                     |

Toàn bộ vị trí bit lấy từ hằng `GVL_O5D150_Def.stPdLayout` (ST_O5D150_PdLayout: usiOut1Bit, usiOut2Bit, usiDistOffset, usiDistLen, rGradient, rOffset, uiNoSignalRaw) để sửa sau khi có IODD mà không đổi logic.

Bảng tham số O5D150 (`GVL_O5D150_Def.aParamDef`):

| E_O5D150_Param     | Tên IODD (dự kiến)                     | Index   | Sub | Kiểu                  | RW  | Đơn vị / Range                                                                                               | Trạng thái                                        |
| ------------------ | -------------------------------------- | ------- | --- | --------------------- | --- | ------------------------------------------------------------------------------------------------------------ | ------------------------------------------------- |
| VENDOR_NAME        | Vendor Name                            | 16      | 0   | StringT ≤64           | RO  | –                                                                                                            | Chuẩn IO-Link (tin cậy)                           |
| VENDOR_TEXT        | Vendor Text                            | 17      | 0   | StringT               | RO  | –                                                                                                            | Chuẩn                                             |
| PRODUCT_NAME       | Product Name                           | 18      | 0   | StringT               | RO  | –                                                                                                            | Chuẩn                                             |
| PRODUCT_ID         | Product ID                             | 19      | 0   | StringT               | RO  | –                                                                                                            | Chuẩn                                             |
| PRODUCT_TEXT       | Product Text                           | 20      | 0   | StringT               | RO  | –                                                                                                            | Chuẩn                                             |
| SERIAL_NO          | Serial Number                          | 21      | 0   | StringT ≤16           | RO  | –                                                                                                            | Chuẩn                                             |
| HW_REV             | Hardware Revision                      | 22      | 0   | StringT               | RO  | –                                                                                                            | Chuẩn                                             |
| FW_REV             | Firmware Revision                      | 23      | 0   | StringT               | RO  | –                                                                                                            | Chuẩn                                             |
| APP_TAG            | Application Specific Tag               | 24      | 0   | StringT 16..32        | RW  | –                                                                                                            | Chuẩn (nếu device hỗ trợ)                         |
| DEVICE_STATUS      | Device Status                          | 36      | 0   | UINT8 0..4            | RO  | 0 OK,1 Maint,2 Out of spec,3 Func check,4 Failure                                                            | Chuẩn                                             |
| DETAILED_STATUS    | Detailed Device Status                 | 37      | 0   | Array of 3-byte event | RO  | –                                                                                                            | Chuẩn (tùy chọn)                                  |
| PDIN_COPY          | Process Data Input                     | 40      | 0   | OCTET                 | RO  | –                                                                                                            | Chuẩn – dùng để test IOL_CALL không cần biết IODD |
| SYS_CMD            | System Command                         | 2       | 0   | UINT8                 | WO  | 0x80 Device reset, 0x81 Application reset, 0x82 Restore factory settings; teach SP1/SP2 = lệnh vendor 0xA0.. | Index chuẩn; **mã teach: IODD**                   |
| ACCESS_LOCKS       | Device Access Locks                    | 12      | 0   | UINT16                | RW  | bit0 param, bit1 data storage, bit2 local param, bit3 local UI                                               | Chuẩn                                             |
| SP1                | Switch point 1 (OUT1)                  | **TBD** | TBD | UINT16 (giả định)     | RW  | mm, min/max theo range (dự kiến ~30..2000 mm)                                                                | **IODD**                                          |
| RP1 / hysteresis 1 | Reset point / hysteresis OUT1          | TBD     | TBD | UINT16                | RW  | mm                                                                                                           | **IODD**                                          |
| OU1                | Output function OUT1 (Hno/Hnc/Fno/Fnc) | TBD     | TBD | UINT8 enum            | RW  | enum                                                                                                         | **IODD**                                          |
| SP2, RP2, OU2      | tương tự OUT2                          | TBD     | TBD |                       | RW  |                                                                                                              | **IODD**                                          |
| UNIT               | Display unit (mm / inch)               | TBD     | TBD | UINT8 enum            | RW  | enum                                                                                                         | **IODD**                                          |
| DS/DR              | Switch-on / switch-off delay           | TBD     | TBD | UINT16                | RW  | s hoặc ms                                                                                                    | **IODD**                                          |
| DISP               | Display mode / rotation / off          | TBD     | TBD | UINT8 enum            | RW  |                                                                                                              | **IODD**                                          |

Ghi chú: Vendor ID ifm = 310 (0x0136) – khớp VendorID GSDML. **Device ID O5D150, độ dài PDin, measuring range, mọi index vendor-specific (SP/rP/ou/uni…) và mã system command teach: chưa xác minh** – điền từ IODD `ifm-…-O5D150-…-IODD1.1.xml` (ioddfinder.io-link.com hoặc ifm.com → Downloads).

### 4.9 Map IODD → DUT/hằng số

Giai đoạn 1 (O5D150): **bảng tay** – kỹ sư mở IODD, đọc `ProcessDataIn` (bitLength, RecordItem bitOffset, Gradient/Offset, SingleValue) và `VariableCollection` (Variable id/index/accessRights/Datatype/ValueRange/SingleValue/StdVariableRef) → điền `GVL_O5D150_Def` + `E_O5D150_Param`.

Giai đoạn 2 (từ device thứ 2): **script sinh code ngoài CODESYS** `D:\Codesys_Demo\tools\iodd2st.py` (Python, đọc IODD XML, resolve text từ `ExternalTextCollection` ngôn ngữ en/vi) → sinh 3 file: `E_<Model>_Param.st`, `GVL_<Model>_Def.st`, `ST_<Model>_PdIn.st` + khung `FB_Dev_<Model>` (chỉ `DecodePdIn` cần viết tay) → nhập vào project bằng skill `plc-import`. Script chỉ sinh text, không động vào project trực tiếp.

## 5. State machine / trình tự

### 5.1 `FB_IolMaster` – `E_IolCallState`

| Step                                                | Hành động                                                                                 | Điều kiện chuyển                                   | Timeout       | Xử lý lỗi                                                                |
| --------------------------------------------------- | ----------------------------------------------------------------------------------------- | -------------------------------------------------- | ------------- | ------------------------------------------------------------------------ |
| IDLE                                                | `xBusy:=FALSE`; nếu FIFO không rỗng → lấy handle, build `abTx` (header + data)            | FIFO có phần tử AND xEnable → WRITE_REQ            | –             | –                                                                        |
| WRITE_REQ                                           | `itfRec.Write(xReq:=TRUE, INDEX:=CAP, LEN:=8+n)`; start `tonTimeout`                      | xDone → READ_WAIT; xError → kiểm STATUS            | tCALL_TIMEOUT | STATUS B5/C3 → RETRY_WR; khác → ERROR (PNIO)                             |
| RETRY_WR                                            | `itfRec.Write(xReq:=FALSE)`; chờ `tonRetry`                                               | hết tRETRY_DELAY AND iRetry<iMAX_RETRY → WRITE_REQ | chung         | vượt retry → ERROR (LOCK/busy)                                           |
| READ_WAIT                                           | Write xReq:=FALSE (1 chu kỳ hạ REQ), chờ tRETRY_DELAY                                     | → READ_REQ                                         | chung         | –                                                                        |
| READ_REQ                                            | `itfRec.Read(xReq:=TRUE, INDEX:=CAP, MLEN:=240)`                                          | xValid → PARSE; xError → STATUS                    | chung         | B5/C3 (master chưa xong) → READ_WAIT (retry); khác → ERROR (PNIO)        |
| PARSE                                               | `ParseResponse`: kiểm 0x08/port/0xFE4A/index echo; Control = request → OK; 0x80 → lỗi IOL | OK → DONE; lỗi → ERROR                             | –             | khung sai → ERROR (FRAME)                                                |
| DONE                                                | copy data/len vào `aRes[h]`, `axResReady[h]:=TRUE`, `udiCallCount+1`                      | → IDLE (chu kỳ sau, sau khi hạ REQ)                | –             | –                                                                        |
| ERROR                                               | ghi mã lỗi vào `aRes[h]`, `axResReady[h]:=TRUE`, `udiErrCount+1`, hạ REQ                  | → IDLE                                             | –             | Không chặn hàng đợi                                                      |
| TIMEOUT (nhánh từ mọi state bận khi `tonTimeout.Q`) | hạ REQ của WRREC/RDREC, đợi BUSY của CommFB về FALSE (tối đa thêm 1 s)                    | → ERROR (TIMEOUT)                                  | –             | Nếu CommFB vẫn BUSY sau 1 s → `eState := STUCK`, chỉ thoát bằng `xReset` |

Ghi chú: CommFB yêu cầu **giữ REQ cho tới khi DONE/VALID/ERROR** rồi hạ xuống ít nhất 1 lần gọi trước request kế tiếp – state machine luôn có 1 chu kỳ hạ REQ.

### 5.2 `FB_IolCall`

| Step       | Hành động                                              | Chuyển                                | Timeout                     | Lỗi                              |
| ---------- | ------------------------------------------------------ | ------------------------------------- | --------------------------- | -------------------------------- |
| IDLE       | chờ `rtExec.Q`                                         | kiểm tham số OK → Submit → WAIT_QUEUE | –                           | sai tham số → ERR (PARAM)        |
| WAIT_QUEUE | xBusy:=TRUE; `refMaster.Poll(h)`                       | kết quả về → DONE / ERR               | 2×tCALL_TIMEOUT (TON riêng) | quá hạn → Cancel → ERR (TIMEOUT) |
| DONE       | xDone:=TRUE, copy len                                  | xExecute=FALSE → IDLE                 | –                           | –                                |
| ERR        | xError:=TRUE, mã lỗi, `wsErrText := F_IolErrText(...)` | xExecute=FALSE → IDLE                 | –                           | –                                |

### 5.3 `FB_IolDevBase` – trình tự ReadAll / WriteAll

| Step     | Hành động                                                     | Chuyển                                                | Lỗi                                    |
| -------- | ------------------------------------------------------------- | ----------------------------------------------------- | -------------------------------------- |
| IDLE     | chờ lệnh (sườn lên, R_TRIG riêng cho mỗi lệnh)                | ReadIdent → RD_IDENT; ReadAll → RD_PARAM(iCur:=first) | –                                      |
| RD_IDENT | đọc lần lượt 16..24, 36                                       | hết → IDLE/RD_PARAM                                   | lỗi từng index lưu vào aVal, tiếp tục  |
| RD_PARAM | `fbCall` READ index/sub của iCur → DecodeValue                | Done → NEXT                                           | uiErr lưu, tiếp tục                    |
| WR_PARAM | chỉ tham số RW AND xDirty: EncodeValue (kiểm min/max) → WRITE | Done → xDirty:=FALSE → NEXT                           | ngoài range → không gửi, uiErr = PARAM |
| NEXT     | iCur+1                                                        | hết → (sau WriteAll) RD_PARAM toàn bộ / DONE          | –                                      |
| DONE     | xBusy:=FALSE                                                  | → IDLE                                                | –                                      |

Device không bao giờ gửi request khi `NOT xPdValid AND NOT stDiag.xDevAvail` (port không có device) → báo "Port không có thiết bị" thay vì chờ timeout.

## 6. Interlock & an toàn

1. IO-Link Call là kênh **tham số / chẩn đoán**, không dùng cho chức năng an toàn. O5D150 OUT1/OUT2 (nếu dùng trong logic) đọc từ PDin cyclic và chỉ khi `xValid`; mất PQ → logic dùng giá trị fail-safe (FALSE).
2. **Ghi tham số và System Command (factory reset, teach) chỉ cho phép ở chế độ Maintenance** (`GVL_HMI` hiện có E_SeqMode – cần xác nhận có mode Maintenance/Manual) và khi máy dừng; HMI yêu cầu xác nhận 2 bước cho factory reset / teach.
3. Mất kết nối PROFINET (AR down): `PN_Controller` / `AL1100` diag (dùng `<AL1100>.xRunning` hoặc biến diag của device instance – tên chính xác cần kiểm sau khi thêm device) → master đưa mọi request đang chờ về ERROR, không gửi mới; PDin coi như invalid.
4. Warm/cold start: không có trạng thái IO-Link nào RETAIN; tham số thực nằm trong cảm biến (và Data Storage của AL1100 nếu bật). Sau khởi động: tự `ReadIdent` + `ReadAll` 1 lần khi `xPdValid` lần đầu lên (cấu hình `xAutoReadOnConnect`, mặc định TRUE).
5. Application STOP: output PROFINET theo cấu hình AL1100 Fail-safe record 300 (mặc định 0 – O5D150 không có PDout nên không ảnh hưởng).
6. Hàng đợi đầy (16 client) → `Register` trả 0 → device báo lỗi LOCK, không treo.

### 6.3 Điểm phải xác minh trên thiết bị thật (blocker kỹ thuật)

- Subslot nhận CAP 0xB400: thử **Slot 1 / Subslot 1 (IO-Link Master, API 0x4E01)** trước; nếu RDREC/WRREC báo `DE 80 B0/B2` → thử **Slot 0 / Subslot 1 (DAP)**; sau cùng thử subslot port (2..5) với byte Port = 0. Ghi kết quả vào GVL_IolConst.
- `CommFB` có xử lý API ≠ 0 tự động theo submodule không (record IO-Link profile nằm trong API 0x4E01).
- Kiểu chân RECORD của `CommFB.RDREC/WRREC`, ý nghĩa `LEN`, INDEX là INT (B400 âm).
- Control phản hồi và vị trí byte mã lỗi trong response.
- License PN Controller trên TBEN; runtime TBEN 3.5.18 chạy được PN Controller 3.5.16.20 (devdesc ghim version này – không update lên 4.x).

## 7. Alarm / cảnh báo

Bit-alarm trong GVL (không dùng Alarm Manager ở giai đoạn này, giữ đồng bộ project hiện có – cần xác nhận).

| Alarm                    | Mức          | Điều kiện                                          | Reset                         |
| ------------------------ | ------------ | -------------------------------------------------- | ----------------------------- |
| `GVL_HMI_IOL.xAlmPnDown` | Lỗi          | AR AL1100 không chạy > 2 s                         | tự hết khi AR lên             |
| `xAlmP1_NoDevice`        | Cảnh báo     | PQI.DA = 0 trên port 1 (đã cấu hình IO-Link) > 2 s | tự hết                        |
| `xAlmP1_PdInvalid`       | Cảnh báo     | DA=1 AND PQ=0 > 1 s                                | tự hết                        |
| `xAlmP1_DevStatus`       | Cảnh báo/Lỗi | Device Status (36) ≥ 2 (≥4 = Lỗi)                  | đọc lại = 0                   |
| `xAlmP1_DevErr` (PQI.DE) | Cảnh báo     | bit DE = 1                                         | tự hết                        |
| `xAlmIolCallErr`         | Thông tin    | lần gọi cuối lỗi (bất kỳ device)                   | nút Reset HMI                 |
| `xAlmMasterStuck`        | Lỗi          | `eState = STUCK`                                   | `xReset` từ HMI (Maintenance) |
| `xAlmO5D150_NoSignal`    | Cảnh báo     | `stPd.xNoSignal` > tNoSignal (thông số)            | tự hết                        |

`GVL_HMI_IOL.xAlarmAny` = OR tất cả mức Lỗi.

## 8. Thông số & HMI

Biến giao tiếp visu trong **`GVL_HMI_IOL`** (GVL mới, `qualified_only`) để không làm rối `GVL_HMI` có sẵn – hoặc gộp vào `GVL_HMI` nếu người dùng muốn (mục 13).

| Biến             | Kiểu                                                                                                                   | Đơn vị | Min/Max                               | RETAIN                                                                   |
| ---------------- | ---------------------------------------------------------------------------------------------------------------------- | ------ | ------------------------------------- | ------------------------------------------------------------------------ |
| `xSimMode`       | BOOL                                                                                                                   | –      | –                                     | Không (đặt ở GVL_IolSys, mặc định FALSE; Simulation đặt TRUE bằng Write) |
| `tCallTimeout`   | TIME                                                                                                                   | ms     | 1 s .. 30 s                           | PERSISTENT (tùy chọn)                                                    |
| `astPort[1..4]`  | `ST_HMI_IolPort` (model text, PQI bits, DevStatus, wsErr)                                                              | –      | –                                     | Không                                                                    |
| `stP1_O5D150`    | `ST_HMI_O5D150` (cmd ReadAll/WriteAll/ReadIdent/Teach/FactoryReset, bConfirm, aVal hiển thị)                           | –      | –                                     | Không                                                                    |
| `stGeneric`      | `ST_HMI_IolGeneric` (port, index, sub, service, dữ liệu hex `STRING(80)`, kết quả hex, xExecute, xDone, xError, wsErr) | –      | port 1..4, index 0..65535, sub 0..255 | Không                                                                    |
| `tNoSignalDelay` | TIME                                                                                                                   | s      | 0..10 s                               | PERSISTENT (tùy chọn)                                                    |

Không RETAIN giá trị tham số cảm biến (nguồn thật là cảm biến). Setpoint SP1/SP2 nhập trên HMI lưu tạm `rSetEng` + `xDirty`, chỉ ghi khi bấm Write.

Visu (CODESYS Visualization, chuỗi `WSTRING`, kiểm `codesys_visu_status` trước – memory: Visual Element Repository từng hỏng; font gán bằng script từng làm hỏng codegen):

- `VT_IolGeneric` – Interface: `refHmi : REFERENCE TO ST_HMI_IolGeneric`. Combobox port, ô nhập index/sub, chọn Read/Write, ô hex, nút Execute, đèn Busy/Done/Error, text lỗi.
- `VT_Dev_O5D150` – Interface: `refHmi : REFERENCE TO ST_HMI_O5D150`, `refDev : REFERENCE TO FB_Dev_O5D150`. Vùng 1: process data (khoảng cách mm dạng số + bar 0..range, đèn OUT1/OUT2, PQ/DA/DE). Vùng 2: bảng tham số (Table element trên `aVal`: tên, giá trị, đơn vị, min/max, RW, trạng thái). Vùng 3: Identification (16..24). Nút: Read all, Write, Read ident, Teach SP1/SP2, Factory reset (ẩn khi không Maintenance, xác nhận 2 bước). Vùng 4: chẩn đoán (Device Status, lỗi gần nhất).
- `Visu_IOLink` – 4 ô port; Frame đổi template theo model của port; nút từ `Visu_Main` sang.
- WebVisu trên TBEN runtime 3.5.18: memory ghi nhận WebVisu SP21 kẹt "Loading" → giữ cấu hình visu hiện hành của project (không đổi profile) và kiểm lại sau khi thêm màn hình mới.

## 9. Quy ước đặt tên

(Theo giả định vì chưa đọc được POU cũ – agent code phải kiểm `GVL_IO`, `FB_OutSeq`, `E_SeqMode` và theo kiểu cũ nếu khác.)

- Tiền tố biến: `x` BOOL, `b` BYTE, `w` WORD, `dw` DWORD, `usi/ui/udi` USINT/UINT/UDINT, `i/di` INT/DINT, `r` REAL, `t` TIME, `s` STRING, `ws` WSTRING, `a` ARRAY, `st` STRUCT, `e` ENUM, `fb` instance FB, `p` POINTER, `ref` REFERENCE, `itf` interface, `ton/rt` timer/trigger.
- POU: `FB_Iol*` (chung), `FB_Dev_<Model>` (device), `F_Iol*` (function), `ITF_Iol*`, `PRG_IOLink`.
- DUT: `ST_`, `E_`, theo model: `ST_<Model>_PdIn`, `E_<Model>_Param`, `ST_HMI_<Model>`.
- GVL: `GVL_IolConst`, `GVL_IolSys`, `GVL_<Model>_Def`, `GVL_HMI_IOL`.
- Visu: `VT_` cho template, `Visu_` cho màn hình.
- Instance device: `fbDevP<port>` hoặc `fbDev<Tag>` (vd `fbDevP1` = O5D150).
- Master: `fbAL<n>` (vd `fbAL1`).

## 10. Kế hoạch kiểm thử

**Giai đoạn A – CODESYS Simulation (không có PROFINET thật):** đặt `GVL_IolSys.xSimMode := TRUE` → master dùng `fbMockAL1`. Lưu ý: với PN_Controller trong cây thiết bị, Simulation sẽ bỏ qua I/O driver; nếu build Simulation báo lỗi do device → tạm Disable device AL1100 (Exclude from build không áp dụng cho device; dùng "Disable device") chỉ trong lúc mô phỏng – xác nhận khi chạy thử.

| Nhóm                  | Case                                                                                                            |
| --------------------- | --------------------------------------------------------------------------------------------------------------- |
| A1 Khung              | Build header Read/Write đúng byte (so với bảng 4.2) – watch `abTx`; parse response OK/lỗi                       |
| A2 Handshake          | Execute → Busy → Done; Execute giữ TRUE → Done giữ; Execute rớt giữa chừng → kết quả 1 chu kỳ; Execute lại ngay |
| A3 Khóa / hàng đợi    | 3 client Execute cùng chu kỳ → chạy tuần tự đúng FIFO, `usiActiveClient` chỉ 1                                  |
| A4 Retry              | Mock trả B5 3 lần → vẫn Done; trả B5 vượt iMAX_RETRY → Error                                                    |
| A5 Timeout            | Mock không trả lời → ERROR TIMEOUT sau tCALL_TIMEOUT, master về IDLE, client kế tiếp chạy được                  |
| A6 Lỗi device         | Mock trả 0x8011, 0x8023, 0x8030 → text đúng                                                                     |
| A7 Lỗi tham số        | Port 5, len 233, pData = 0 → PARAM, không gửi                                                                   |
| A8 Device O5D150      | Force `GVL_IO.abAL1_P1_In`/`bAL1_P1_PQI` → khoảng cách, OUT1/2, PQ=0 → xValid FALSE                             |
| A9 ReadAll / WriteAll | Giá trị ngoài min/max bị chặn; WriteAll ghi chỉ xDirty; đọc lại xác nhận                                        |
| A10 HMI               | Visu template O5D150 + generic trên Simulation                                                                  |

**Giai đoạn B – thiết bị thật (TBEN + AL1100 + O5D150):** bắt buộc cho: kết nối PROFINET (AR, station name, IP), subslot CAP, kiểu INDEX âm, response layout/mã lỗi thật, timing ISDU, PDin layout thật (so với hiển thị trên cảm biến), teach/system command, mất kết nối cáp, rút cảm biến khỏi port (DA=0), license PN.

Thứ tự B: B1 AR lên, PQI port 1 → B2 IOL_CALL đọc index 16/18 qua `VT_IolGeneric` (xác định subslot CAP) → B3 đọc index 40 so với PDin cyclic → B4 đọc/ghi tham số vendor theo IODD → B5 ReadAll/WriteAll O5D150 → B6 mất kết nối / rút device → B7 chạy dài 1 h (đếm `udiErrCount`).

## 11. Biến Watch khi test Simulation

| Biến                                                                                         | Vai trò              | Cách tác động khi test      |
| -------------------------------------------------------------------------------------------- | -------------------- | --------------------------- |
| `GVL_IolSys.xSimMode`                                                                        | Chọn mock            | Write TRUE                  |
| `GVL_IolSys.fbAL1.eState`                                                                    | State machine master | Chỉ Watch                   |
| `GVL_IolSys.fbAL1.usiActiveClient` / `.uiQueueCount`                                         | Khóa / hàng đợi      | Chỉ Watch                   |
| `GVL_IolSys.fbAL1.abTx` / `.abRx`                                                            | Khung gửi/nhận       | Chỉ Watch                   |
| `GVL_IolSys.fbAL1.udiCallCount` / `.udiErrCount`                                             | Thống kê             | Chỉ Watch                   |
| `GVL_IolSys.fbMockAL1.xInjNoResponse` / `.usiInjBusyCount` / `.uiInjDevErr` / `.xInjPnioErr` | Chèn lỗi             | Write                       |
| `GVL_IolSys.fbMockAL1.tDelayRd`                                                              | Độ trễ giả lập       | Write                       |
| `GVL_IO.abAL1_P1_In[0..1]`                                                                   | PDin O5D150          | Write/Force                 |
| `GVL_IO.bAL1_P1_PQI`                                                                         | Port qualifier       | Write/Force (16#90 = PQ+DA) |
| `PRG_IOLink.fbDevP1.stPd`                                                                    | PD đã giải mã        | Chỉ Watch                   |
| `PRG_IOLink.fbDevP1.aVal`                                                                    | Giá trị tham số      | Watch                       |
| `PRG_IOLink.fbDevP1.fbCall.xBusy/.xDone/.xError/.uiIolDevErr/.wsErrText`                     | Handshake            | Chỉ Watch                   |
| `GVL_HMI_IOL.stGeneric.*`                                                                    | Lệnh generic         | Write (xExecute, index…)    |
| `GVL_HMI_IOL.stP1_O5D150.xCmdReadAll` / `.xCmdWriteAll`                                      | Lệnh device          | Write                       |
| `GVL_HMI_IOL.xAlarmAny`                                                                      | Alarm chung          | Chỉ Watch                   |

Bắt buộc test trên thiết bị thật: mọi case nhóm B (PROFINET, CAP subslot, mã lỗi thật, timing, PDin thật, license).

## 12. Các bước triển khai

0. Người dùng trả lời mục 13 (tối thiểu: IODD O5D150, IP/station name AL1100, license PN). Load skill **`plc-import`** (phần CODESYS) trước mọi thao tác ghi. Save project hiện tại (đang dirty) trước khi bắt đầu.
1. Library Manager: gỡ 3 lib Turck IO-Link CALL (sau khi kiểm không POU nào dùng); xử lý namespace Turck commfb* nếu trùng.
2. Cây thiết bị: thêm Ethernet → PN_Controller 3.5.16.20 → AL1100 (DIM 1) → submodule port 1 "IO-Link 2I" (hoặc theo IODD), port 2..4 "INACTIVATE"; đặt IP/station name, bus cycle task = MainTask. Nếu làm bằng script → save/close/reopen. Build kiểm tra; đọc lại tên instance device (`<AL1100>.DeviceID`) và địa chỉ %IB.
3. I/O mapping port 1 → `GVL_IO.abAL1_P1_In`, `GVL_IO.bAL1_P1_PQI` (map vào biến có sẵn sau khi khai báo ở bước 5 – hoặc khai trước biến trong GVL_IO).
4. DUT: E_IolCallState, E_IolService, E_IolDataType, E_IolAccess, E_IolErrSource, ST_IolRequest, ST_IolResult, ST_IolParamDef, ST_IolParamVal, ST_IolPortDiag, ST_IolIdent, ST_O5D150_PdLayout, ST_O5D150_PdIn, E_O5D150_Param, ST_HMI_*.
5. GVL: GVL_IolConst, GVL_IO (thêm biến), GVL_O5D150_Def, GVL_HMI_IOL.
6. INTERFACE ITF_IolRecordAccess.
7. FUNCTION: F_IolGet/SetU16BE, U32BE, R32BE, F_IolGetBits, F_IolErrText.
8. FB: FB_PnRecordAccess, FB_MockRecordAccess, FB_IolMaster, FB_IolCall, FB_IolDevBase, FB_Dev_O5D150.
9. GVL_IolSys (instance master/transport – sau khi các FB tồn tại).
10. PROGRAM PRG_IOLink; thêm lời gọi `PRG_IOLink();` cuối PLC_PRG (một dòng, không đổi logic cũ).
11. Visu: VT_IolGeneric → VT_Dev_O5D150 → Visu_IOLink; nút chuyển từ Visu_Main.
12. Build (0 error) → save → test Simulation (mục 10 A) → login thiết bị thật (mục 10 B).

## 13. Giả định & câu hỏi mở

**Giả định**

1. O5D150 cắm **Port 1 (X01)** – đổi bằng `GVL_IolConst.usiPORT_O5D150`; port 2..4 chưa có thiết bị (INACTIVATE).
2. PDin O5D150 = **2 byte** (submodule "IO-Link 2I"), OUT1 = bit0, OUT2 = bit1, khoảng cách = bit 4..15, 1 digit = 1 mm – **chưa xác minh**, toàn bộ nằm trong hằng `GVL_O5D150_Def.stPdLayout`.
3. Index vendor-specific O5D150 (SP1/SP2, rP, ou1/ou2, unit, delay, display) và mã teach system command **chưa có** – để TBD, điền từ IODD. Index chuẩn 2, 12, 16–24, 36, 37, 40 tin cậy theo IO-Link spec.
4. CAP 0xB400 nằm ở **Slot 1 / Subslot 1** (submodule "IO-Link Master"); phương án dự phòng Slot 0 / Subslot 1. Layout response lỗi (Control 0x80, byte 5..8) theo hiểu biết spec PNO/Siemens – chưa đối chiếu tài liệu gốc.
5. Dùng `CommFB.RDREC/WRREC` + `CommFB.SUBSLOT_ID` (đã thấy trong lib); kiểu chân RECORD cần xem trong Library Manager khi viết code.
6. MainTask là bus cycle task của PN Controller, chu kỳ ≤ 10 ms; IO cycle AL1100 4–8 ms.
7. Không dùng Alarm Manager; bit-alarm trong `GVL_HMI_IOL`. Ghi tham số/teach chỉ ở chế độ Maintenance.
8. Chưa đọc được nội dung PLC_PRG/GVL_IO/GVL_HMI/E_SeqMode (bridge lỗi khi read) → quy ước đặt tên giả định; agent code đọc lại trước khi ghi.

**Câu hỏi cho người dùng**

1. **File IODD O5D150** (.xml, kèm phiên bản) – hoặc đường dẫn tải về máy. Cần cho: Device ID, PDin length/layout, index tham số, mã teach. Có thể gửi luôn bản PDF "IO-Link device description" của ifm.
2. O5D150 thực sự cắm port nào? Port 2..4 sẽ cắm model gì (model + IODD từng cái), có device nào có PDout không?
3. AL1100: IP và PROFINET station name muốn đặt? Firmware AL1100 bao nhiêu (để đối chiếu manual IOL_CALL)? Có manual AL1100 hoặc spec PNO "IO-Link Integration for PROFINET" để xác nhận layout response lỗi không?
4. TBEN-L5-PLC-11 đã có **license CODESYS PROFINET Controller** chưa? (nếu không: chạy demo giới hạn, không dùng được sản xuất).
5. Chu kỳ MainTask hiện tại là bao nhiêu? Có cho phép đặt MainTask làm bus cycle task PN không?
6. Có cổng Ethernet nào của TBEN dành riêng cho mạng PROFINET không, hay dùng chung mạng 192.168.2.x với WebVisu/lập trình?
7. Đồng ý **gỡ 3 lib Turck IO-Link CALL** (và Turck commfb* nếu không dùng)? Có POU nào khác đang dùng chúng không?
8. E_SeqMode có chế độ Maintenance/Manual để khóa ghi tham số/teach không? Nếu không, khóa bằng gì (mật khẩu visu user management?)
9. Biến HMI IO-Link đặt trong GVL mới `GVL_HMI_IOL` hay gộp vào `GVL_HMI` có sẵn?
10. Visu chạy WebVisu trên TBEN hay TargetVisu/PC? (memory: WebVisu SP21 trên runtime 3.5.18 từng kẹt Loading).
11. Có muốn script sinh code `iodd2st.py` ngay từ device đầu tiên, hay làm tay O5D150 trước rồi mới viết script?
