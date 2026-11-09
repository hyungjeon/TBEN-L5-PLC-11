# Báo cáo code 01 – IO-Link O5D150 qua AL1100 (TBEN-L5-PLC-11)

Ngày: 2026-11-07 · Project: `D:\Codesys_Demo\TBEN_L5_PLC11.project` (CODESYS V3.5 SP21 P1) · Plan: `D:\Codesys_Demo\plan\plan.md` (ĐÃ DUYỆT)

## 1. Trạng thái

> Cập nhật 2026-11-07: người dùng xác nhận bỏ qua lỗi Ethernet (sẽ cấu hình vào thứ 2), nên project **đã được save**. Phiên chính đã gỡ 3 lib Turck IO-Link CALL. Các dòng bên dưới ghi "CHƯA save" và "chưa gỡ lib" là thông tin cũ.

- **Build: 1 lỗi, 0 warning** – lỗi duy nhất là `The Ethernet interface is not configured.`. Lỗi này đến từ device `TBEN_L5_PLC_11/Ethernet/PN_Controller`. Hai device này **đã có sẵn trong phiên CODESYS đang mở (project dirty)**, không do agent code thêm, và plan ghi là chưa có. Theo quyết định Q3/Q4, agent không sửa cấu hình thiết bị.
- Phần code đã được biên dịch và kiểm ngữ nghĩa: đã chèn thử 1 lỗi định danh vào `FB_IolCall.SetError`, build báo đúng lỗi đó, sau đó đã gỡ lỗi thử. Với lỗi Ethernet, build dừng trước bước "Generate code", nên warning ở bước sinh code (nếu có) chưa thấy được.
- **CHƯA save project**, theo quy tắc không save khi build còn lỗi. Toàn bộ code đã được export ra `src\` và import lại được.
- **Chưa gỡ 3 lib Turck IO-Link CALL (Q7)**: bridge MCP không có lệnh sửa Library Manager, và `codesys_run_script` không có trong bộ công cụ của agent. Không POU nào của project dùng `IOL_CALL` (kiểm trên toàn bộ code đã export).

### Người dùng cần chọn 1 trong 2 cách

1. Cấu hình interface cho device `Ethernet` (chọn card mạng của TBEN), hoặc Disable/Delete `Ethernet` + `PN_Controller` nếu không phải người dùng chủ động thêm, rồi Build. Kết quả mong đợi: 0 lỗi, sau đó Save.
2. Gỡ tay trong Library Manager: `IO-Link CALL Base`, `IO-Link CALL Local IO`, `IO-Link CALL Modbus TCP`.

## 2. Đối tượng tạo/sửa (dưới `TBEN_L5_PLC_11/Plc Logic/Application/`)

**Sửa**

- `GVL_IO`: giữ nguyên, thêm `abAL1_P1_In : ARRAY[0..1] OF BYTE`, `bAL1_P1_PQI : BYTE`. Đây là biến thường, có TODO map I/O khi thêm AL1100.
- `PLC_PRG`: chỉ thêm `PRG_IOLink();` ở cuối thân. Đã diff với bản gốc: khai báo giữ nguyên, thân chỉ khác 3 dòng thêm.

**Tạo – `IOLink/Common/`**

- ENUM: `E_IolCallState`, `E_IolService`, `E_IolErrSource`, `E_IolDataType`, `E_IolAccess`, `E_IolCallStep`, `E_IolDevSeq`, `E_IolDevJob`, `E_IolEvtType`
- STRUCT: `ST_IolRequest`, `ST_IolResult`, `ST_IolParamDef`, `ST_IolParamVal`, `ST_IolPortDiag`, `ST_IolIdent`, `ST_IolEventDef`, `ST_MockParam`
- GVL: `GVL_IolConst` (CONSTANT), `GVL_IolSys` (`xSimMode := TRUE`, `fbMockAL1`, `fbPnAL1`, `fbAL1`)
- FUNCTION: `F_IolGetU16BE`, `F_IolSetU16BE`, `F_IolGetU32BE`, `F_IolSetU32BE`, `F_IolGetR32BE`, `F_IolSetR32BE`, `F_IolBytesToStr`, `F_IolIsPnioBusy`, `F_IolErrText`
- `ITF_IolRecordAccess` (Write/Read), `FB_PnRecordAccess` (**khung**), `FB_MockRecordAccess` (+8 method), `FB_IolMaster` (Register/Submit/Poll/Cancel/BuildFrame/ParseResponse/Finish), `FB_IolCall` (+SetError), `FB_IolDevBase` (+19 method)

**Tạo – `IOLink/O5D150/`**: `E_O5D150_Param`, `ST_O5D150_PdLayout`, `ST_O5D150_PdIn`, `ST_HMI_O5D150`, `GVL_O5D150_Def`, `FB_Dev_O5D150 EXTENDS FB_IolDevBase` (+8 method)

**Tạo – `IOLink/`**: `GVL_HMI_IOL`, `PRG_IOLink`

Tổng cộng: 42 đối tượng mới, 2 đối tượng sửa.

## 3. File

- Nguồn: `D:\Codesys_Demo\src\IOLink\*.xml` (PLCopenXML, import lại được), `D:\Codesys_Demo\src\GVL_IO.xml`, `D:\Codesys_Demo\src\PLC_PRG.xml`; bản ST text đọc được: `D:\Codesys_Demo\src\st\*.st`
- Backup: `D:\Codesys_Demo\backup\20261107_151150\` (`TBEN_L5_PLC11.project` = bản trên đĩa lúc 15:09, `PLC_PRG.xml`, `GVL_IO.xml` gốc)
- Comment tiếng Việt có dấu ghi qua bridge bình thường. Đã kiểm bằng cách export ra file. Bridge chỉ lỗi khi trả nội dung có dấu về qua `read_object` hoặc `export_xml` không có `filePath`.

## 4. Điểm khác plan (theo IODD ifm-000174-20210526)

- PDin: Distance 12 bit từ bit 4, **đơn vị cm** (5..200), không phải mm. Chỉ có OUT1 (bit 0), không có OUT2. `rDistance_m = cm × 0.01`.
- Bảng tham số dùng index thật trong IODD: SP1 60/1, Logic 61/1, Limit 64 (tách min/max), Align 69, dFO 74, dS 76, dr 78, Laser 80, Display 96, KeyLock 100. Index 36 (Device Status) và 12 (Access Locks) không có trong IODD nên đã bỏ.
- Không có teach. System Command: 130 (factory reset, mock có xử lý; FB chưa có nút HMI), 240..243 (Test Event).
- Event: đọc index 37 (3 byte/entry); khi nhận 0x8011 thì bật `xEvtListNotSupported` và ngừng đọc chu kỳ, không đẩy lỗi lên HMI. Cờ được xoá khi PD hợp lệ trở lại hoặc khi có lệnh `xCmdReadEvents`.
- Dải min/max trong `ST_IolParamDef` dùng DINT (`diMin/diMax`) thay vì REAL, vì mọi tham số O5D150 là số nguyên. `wsText` tiếng Việt chỉ có ở bảng event.
- Khoá ghi: `GVL_HMI_IOL.xMaintEnable` khoá mọi lệnh ghi (tham số và System Command). Theo Q8, không dùng E_SeqMode.
- Tên enum `LIMITS`, không dùng `LIMIT` vì trùng hàm chuẩn.
- Chưa làm: visu (Q9), `stGeneric` (ISDU tự do từ HMI), ReadOne/WriteAll tổng quát trên HMI, alarm PN down (cần device AL1100).

## 5. TODO bước PROFINET thật

1. Thêm AL1100 (DIM 1) dưới PN_Controller; port 1 = "IO-Link 2I"; bus cycle task = MainTask. Sau khi thêm bằng script thì save/close/reopen.
2. Map Input data/PQI port 1 → `GVL_IO.abAL1_P1_In` / `GVL_IO.bAL1_P1_PQI`.
3. Viết `FB_PnRecordAccess`: `CommFB.WRREC/RDREC` + `CommFB.SUBSLOT_ID(<AL1100>.DeviceID, slot 1, subslot 1)` (chi tiết trong comment khai báo FB). Truyền `dwId` vào `fbAL1`.
4. Xác minh trên thiết bị: subslot nhận CAP, INDEX âm (0xB400 → INT), layout phản hồi lỗi (`FB_IolMaster.ParseResponse`), Control 0x80.
5. Event chính thức: PROFINET diagnosis/alarm của AL1100. Index 37 chỉ là đường phụ.
6. Đặt `GVL_IolSys.xSimMode := FALSE`.

## 6. Test trên CODESYS Simulation (mock)

Online → Simulation → Login → Start. Mặc định `GVL_IolSys.xSimMode = TRUE`.

**Chuẩn bị:** Write `GVL_IO.bAL1_P1_PQI := 16#90` (PQ + DA).

| #   | Thao tác (Write/Force)                                                         | Kết quả mong đợi                                                                                                                                                                                                   |
| --- | ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| C1  | `GVL_IO.abAL1_P1_In[0] := 16#06`, `[1] := 16#41`                               | `PRG_IOLink.fbDevP1.stPd.uiDistance_cm = 100`, `rDistance_m = 1.0`, `xOut1 = TRUE`, `xOutOfRange = FALSE`; HMI `GVL_HMI_IOL.stO5D150.*` giống                                                                      |
| C2  | `[0] := 16#00`, `[1] := 16#30` (3 cm)                                          | `uiDistance_cm = 3`, `xOutOfRange = TRUE`, `xOut1 = FALSE`                                                                                                                                                         |
| C3  | `bAL1_P1_PQI := 16#10` (DA, không PQ)                                          | `xPdValid = FALSE`, `xOut1 = FALSE`, khoảng cách giữ giá trị cũ; sau 1 s `xAlmP1_PdInvalid = TRUE`                                                                                                                 |
| C4  | `bAL1_P1_PQI := 16#00`                                                         | sau 2 s `xAlmP1_NoDevice = TRUE`; việc ISDU đang chờ bị huỷ, `wsErrText` = "Port không có thiết bị…"                                                                                                               |
| A1  | PQI về `16#90` (sườn lên PD hợp lệ)                                            | tự đọc Ident + ReadAll: `sVendor = 'ifm electronic gmbh'`, `sProduct = 'O5D150'`, `uiSP1 = 100`, `uiLimitMin/Max = 5/200`, `usiLaser = 1`, `usiDisplay = 1`, `usiAlign = 75`; `GVL_IolSys.fbAL1.udiCallCount` tăng |
| A2  | `stO5D150.uiSetSP1 := 150`, `xCmdWriteSP1 := TRUE`, khi `xMaintEnable = FALSE` | không gửi; `xError = TRUE`, `wsErrText` = "Ghi bị khoá…"                                                                                                                                                           |
| A3  | `xMaintEnable := TRUE`, `xCmdResetErr := TRUE`, sau đó `xCmdWriteSP1 := TRUE`  | `uiSP1 = 150` (ghi xong rồi đọc lại)                                                                                                                                                                               |
| A4  | `uiSetSP1 := 250`, `xCmdWriteSP1 := TRUE`                                      | chặn trước khi gửi: `wsErrText` = "Giá trị đặt ngoài dải IODD…"                                                                                                                                                    |
| A5  | `usiSetLaser := 0` / `usiSetDisplay := 2` + lệnh ghi tương ứng                 | `usiLaser = 0` / `usiDisplay = 2`                                                                                                                                                                                  |
| A6  | `xAlignMode := TRUE`, đổi `GVL_IolSys.fbMockAL1.usiSimAlign := 40`             | `usiAlign = 40` sau ≤ 0.5 s                                                                                                                                                                                        |
| A7  | `fbMockAL1.uiInjDevErr := 16#8030`, ghi SP1 hợp lệ                             | `xError`, `uiDevErr = 16#8030`, "Thiết bị: giá trị ngoài dải"; trả `uiInjDevErr := 0`                                                                                                                              |
| A8  | `fbMockAL1.usiInjBusyCount := 3`, ReadAll                                      | vẫn xong (retry); `fbAL1.eState` qua READ_WAIT/READ_REQ                                                                                                                                                            |
| A9  | `fbMockAL1.xInjNoResponse := TRUE`, ReadAll                                    | sau 5 s `wsErrText` = "Quá thời gian chờ…", master về IDLE (hoặc STUCK sau 1 s nếu transport còn BUSY → `xCmdResetMaster` khi `xMaintEnable`)                                                                      |
| E1  | `xMaintEnable = TRUE`, `xCmdTestEvt1On := TRUE`                                | `fbMockAL1.usiLastSysCmd = 240`, `xEvt1Active = TRUE`; ngay sau đó `stO5D150.axEvtActive[6] = TRUE`, `uiEvtCount = 1`                                                                                              |
| E2  | `xCmdTestEvt2On` rồi `xCmdTestEvt1Off`                                         | `axEvtActive[7] = TRUE`, `[6] = FALSE`                                                                                                                                                                             |
| E3  | `fbMockAL1.awInjEvent[0] := 16#8CB5`                                           | trong ≤ 5 s `axEvtActive[4] = TRUE`, `GVL_HMI_IOL.xAlmP1_EvtError = TRUE`, `xAlarmAny = TRUE`                                                                                                                      |
| E4  | `fbMockAL1.xIdx37NotSupported := TRUE`, `xCmdReadEvents := TRUE`               | `xEvtListNotSupported = TRUE`, không có lỗi trên `wsErrText`, ngừng đọc chu kỳ (`fbMockAL1.udiRdCount` không tăng đều mỗi 5 s nữa)                                                                                 |
| E5  | `xMaintEnable = FALSE`, `xCmdTestEvt1On`                                       | không gửi, "Ghi bị khoá…"                                                                                                                                                                                          |

Biến để Watch: `GVL_IolSys.fbAL1.eState/abTx/abRx/usiActiveClient/uiQueueCount/udiErrCount`, `PRG_IOLink.fbDevP1.aVal`, `PRG_IOLink.fbDevP1.fbCall.*`.

Sau khi đạt trên Simulation mới đưa xuống TBEN thật (nhóm B trong plan). Agent không login/download.
