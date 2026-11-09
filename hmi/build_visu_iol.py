# -*- coding: utf-8 -*-
# Chay trong codesys_run_script: exec(open(path,'rb').read().decode('utf-8'))
import clr
clr.AddReference("System.Drawing")
from System.Drawing import Color
V = u"GVL_HMI_IOL.stO5D150."
VISU = "Visu_IOL_O5D150"
DIS = u"NOT GVL_HMI_IOL.xMaintEnable"
els = []   # (spec, style)

def _p(x, y, w, h, t=None, var=None, extra=None):
    p = {"Position.X": x, "Position.Y": y, "Position.Width": w, "Position.Height": h}
    if t is not None: p["Texts.Text"] = t
    if var: p["Text variables.Text variable"] = var
    if extra: p.update(extra)
    return p

def R(x, y, w, h, t=u"", var=None, fill=None, frame=None, nofill=False, align=None, extra=None):
    els.append(({"type": "Rectangle", "properties": _p(x, y, w, h, t, var, extra)},
                {"fill": fill, "frame": frame, "nofill": nofill, "align": align}))
def L(x, y, var, s=24):
    els.append(({"type": "Lamp", "properties": {"Position.X": x, "Position.Y": y, "Position.Width": s, "Position.Height": s, "Variable": var}}, {}))
def B(x, y, w, h, t, code=None, dis=False, tog=None, visu=None):
    p = _p(x, y, w, h, t)
    if dis: p["State variables.Deactivate inputs"] = DIS
    if tog: a = [{"event": "OnMouseClick", "kind": "toggle", "variable": tog}]
    elif visu: a = [{"event": "OnMouseClick", "kind": "change_visu", "target": visu}]
    else: a = [{"event": "OnMouseClick", "kind": "execute_st", "code": code}]
    els.append(({"type": "Button", "properties": p, "actions": a}, {}))
def IMG(x, y, w, h, sid):
    els.append(({"type": "Image", "properties": _p(x, y, w, h, None, None, {"Static ID": sid})}, {}))

BG = "E9ECEF"; PANEL = "F3F6F9"; TITLE = "C9D2DC"; FR = "8A97A6"; BAR = "5B6B7D"
def panel(x, y, w, h, title):
    R(x, y, w, h, u"", fill=PANEL, frame=FR)
    R(x, y, w, 24, title, fill=TITLE, frame=FR, align="Left")
def lab(x, y, w, h, t, var=None, align="Left"):
    R(x, y, w, h, t, var, nofill=True, align=align)
def val(x, y, w, h, t, var=None):
    R(x, y, w, h, t, var, fill="F4F6F8", frame="B8C1CC")

# nen + header
IMG(6, 4, 48, 48, u"D:\Codesys_Demo\hmi\img\O5D150_icon.png")
lab(64, 0, 760, 56, u"ifm O5D150 – Cảm biến khoảng cách laser  |  IO-Link Port 1 – AL1100")
B(900, 12, 112, 32, u"< Quay lại", visu=u"Visu_Main")

# P1 process data
panel(10, 64, 500, 190, u" Dữ liệu quá trình (Process Data)")
val(20, 94, 160, 46, u"%d cm", V + u"uiDistance_cm")
val(190, 94, 150, 46, u"%.2f m", V + u"rDistance_m")
R(20, 148, 480, 22, u"", fill="FFFFFF", frame=FR)
R(20, 148, 480, 22, u"", fill=BAR, frame=FR,
  extra={"Relative movement.Movement bottom-right.X": u"-(480 - MIN(480, UINT_TO_INT(" + V + u"uiDistance_cm) * 480 / 200))"})
lab(20, 172, 60, 16, u"0", align="Left"); lab(230, 172, 60, 16, u"100", align="Center"); lab(440, 172, 60, 16, u"200 cm", align="Right")
for (x, y, var, t, w) in [(20, 194, u"xOut1", u"OUT1", 60), (130, 194, u"xDA", u"PQI.DA", 70), (250, 194, u"xPdValid", u"PD hợp lệ", 90), (390, 194, u"xDE", u"PQI.DE", 80),
                          (20, 222, u"xPQ", u"PQI.PQ", 70), (130, 222, u"xOutOfRange", u"Ngoài dải đo (5..200 cm)", 220)]:
    L(x, y, V + var); lab(x + 28, y, w, 24, t)

# P2 tham so
panel(10, 262, 500, 306, u" Tham số (Parameters) – ghi cần bật “Cho phép ghi”")
y = 292
lab(20, y, 90, 30, u"SP1 (cm)"); val(110, y, 92, 30, u"Đọc: %d", V + u"uiSP1"); val(206, y, 52, 30, u"%d", V + u"uiSetSP1")
for x, t, d in [(262, u"-10", -10), (304, u"-1", -1), (346, u"+1", 1), (388, u"+10", 10)]:
    B(x, y, 40, 30, t, V + u"uiSetSP1 := DINT_TO_UINT(LIMIT(5, UINT_TO_DINT(" + V + u"uiSetSP1) + (" + unicode(d) + u"), 200));", dis=True)
B(440, y, 60, 30, u"Ghi", V + u"xCmdWriteSP1 := TRUE;", dis=True)
def row(y, name, rd, st, btns, wr):
    lab(20, y, 90, 30, name); val(110, y, 92, 30, u"Đọc: %d", V + rd); val(206, y, 52, 30, u"%d", V + st)
    for x, t, v in btns: B(x, y, 56, 30, t, V + st + u" := " + unicode(v) + u";", dis=True)
    B(440, y, 60, 30, u"Ghi", V + wr + u" := TRUE;", dis=True)
row(330, u"Logic", u"usiLogic", u"usiSetLogic", [(262, u"0 NO", 0), (322, u"1 NC", 1)], u"xCmdWriteLogic")
row(368, u"Laser", u"usiLaser", u"usiSetLaser", [(262, u"0 Tắt", 0), (322, u"1 Bật", 1)], u"xCmdWriteLaser")
row(406, u"Display", u"usiDisplay", u"usiSetDisplay", [(262, u"0 Tắt", 0), (322, u"1 Bật", 1), (382, u"2 Xoay", 2)], u"xCmdWriteDisplay")
y = 444
lab(20, y, 90, 30, u"Limit"); val(110, y, 140, 30, u"Min: %d cm", V + u"uiLimitMin_cm"); val(256, y, 140, 30, u"Max: %d cm", V + u"uiLimitMax_cm")
y = 482
lab(20, y, 90, 30, u"Align"); val(110, y, 92, 30, u"%d", V + u"usiAlign")
R(206, y + 4, 200, 22, u"", fill="FFFFFF", frame=FR)
R(206, y + 4, 200, 22, u"", fill=BAR, frame=FR, extra={"Relative movement.Movement bottom-right.X": u"-(200 - MIN(200, USINT_TO_INT(" + V + u"usiAlign) * 200 / 100))"})
B(412, y, 88, 30, u"Chế độ Align", tog=V + u"xAlignMode")
B(20, 522, 150, 36, u"Đọc tất cả tham số", V + u"xCmdReadAll := TRUE;")
B(180, 522, 150, 36, u"Đọc nhận dạng", V + u"xCmdReadIdent := TRUE;")

# P3 status bar
R(10, 588, 500, 46, u"", fill=PANEL, frame=FR)
L(20, 599, V + u"xBusy"); lab(48, 599, 110, 24, u"Đang xử lý")
L(170, 599, V + u"xParamValid"); lab(198, 599, 130, 24, u"SP1 đã đọc")
L(340, 599, V + u"xWriteLocked"); lab(368, 599, 130, 24, u"Khóa ghi")

# P4 ident + hinh
panel(520, 64, 494, 130, u" Nhận dạng (Ident)")
IMG(528, 90, 100, 100, u"D:\Codesys_Demo\hmi\img\O5D150_pic.png")
lab(640, 94, 366, 22, u"Hãng: %s", V + u"sVendor")
lab(640, 118, 366, 22, u"Sản phẩm: %s", V + u"sProduct")
lab(640, 142, 366, 22, u"Serial: %s", V + u"sSerial")
lab(640, 166, 366, 22, u"Firmware: %s", V + u"sFwRev")

# P5 event
panel(520, 202, 494, 310, u" Sự kiện (Event) – theo IODD")
names = [u"0x4220 TEMP – quá nhiệt thiết bị", u"0x8CB0 nEA – vật quá gần", u"0x8CB1 fAr – vật quá xa",
         u"0x8CB4 (+) – cường độ phản xạ quá lớn", u"0x8CB5 (-) – không có vật / tín hiệu",
         u"0x8CA4 ErP – sai lệch tính hợp lý", u"0x8DFE Test Event 1", u"0x8DFF Test Event 2"]
for i, n in enumerate(names):
    yy = 232 + i * 26
    L(530, yy, V + u"axEvtActive[%d]" % i, 22); lab(560, yy - 1, 440, 24, n)
for x, t, c in [(530, u"Test 1 xuất hiện", u"xCmdTestEvt1On"), (650, u"Test 1 biến mất", u"xCmdTestEvt1Off"), (770, u"Test 2 xuất hiện", u"xCmdTestEvt2On"), (890, u"Test 2 biến mất", u"xCmdTestEvt2Off")]:
    B(x, 446, 115, 30, t, V + c + u" := TRUE;", dis=True)
L(530, 484, V + u"xEvtListNotSupported", 22); lab(560, 483, 320, 24, u"Không hỗ trợ danh sách event (index 37)")
B(890, 480, 115, 28, u"Đọc event", V + u"xCmdReadEvents := TRUE;")

# P6 loi + khoa
panel(520, 520, 494, 110, u" Lỗi & khóa ghi")
B(530, 550, 230, 32, u"Cho phép ghi (khóa bảo trì)", tog=u"GVL_HMI_IOL.xMaintEnable")
L(772, 554, u"GVL_HMI_IOL.xMaintEnable", 24); lab(802, 554, 200, 24, u"Đã mở khóa ghi")
L(530, 594, V + u"xError", 24); val(560, 590, 250, 30, u"%s", V + u"wsErrText")
val(816, 590, 90, 30, u"Mã: %d", V + u"uiDevErr")
B(912, 588, 94, 34, u"Reset lỗi", V + u"xCmdResetErr := TRUE;")

# ---- chay ----
vis = resolve(VISU)
cmd_visu_remove_elements({"visualization": VISU, "all": True})
res = cmd_visu_add_elements({"visualization": VISU, "elements": [s for s, _ in els]})
errs = [a for a in res["added"] if a.get("propertyErrors")]
def col(h):
    return Color.FromArgb(int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16))
styerr = []
vis.begin_modify()
try:
    byid = {}
    for e in vis.visual_element_list: byid[e.id] = e
    for (spec, st), a in zip(els, res["added"]):
        e = byid[a["id"]]
        for key, pn in [("fill", "Colors.Normal state.Fill color"), ("frame", "Colors.Normal state.Frame color")]:
            if st.get(key):
                try: e.set_property(pn, col(st[key]))
                except Exception as ex: styerr.append((a["id"], pn, str(ex)[:60]))
        if st.get("nofill"):
            for pn, vv in [("Appearance.Fill attributes", "Invisible"), ("Appearance.Line style", "Invisible")]:
                try: e.set_property(pn, vv)
                except Exception as ex: styerr.append((a["id"], pn, str(ex)[:60]))
        if st.get("align"):
            try: e.set_property("Text properties.Horizontal alignment", st["align"])
            except Exception as ex: styerr.append((a["id"], "align", str(ex)[:60]))
finally:
    vis.end_modify()
result = {"n": len(els), "addErrs": errs[:5], "styleErrs": styerr[:8], "nStyleErr": len(styerr)}
