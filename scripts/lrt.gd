extends ShowerBase
# LRT: drag the card through the reader (not too fast, not too slow). Then 6 hygiene questions
# (1 kuman per correct answer), then the boy opens the stall door, enters, the door closes and he showers.

const QUESTIONS := [
	["Berapa kali kita perlu mandi dalam sehari, secara am?", ["Seminggu sekali", "1-2 kali sehari", "5-6 kali sehari", "Bila bau je"], 1],
	["Apakah elemen penting yang disarankan untuk kebersihan diri?", ["Minyak wangi je", "Bedak dan gel rambut", "Sabun, cuci muka, syampu, gosok gigi", "Air kosong sudah cukup"], 2],
	["Apa yang perlu dilakukan untuk jaga kualiti kebersihan diri?", ["Potong kuku, tukar berus gigi tiap 3 bulan", "Tukar berus gigi tiap 3 tahun", "Gigit kuku bila bosan", "Kongsi berus gigi dengan kawan"], 0],
	["Apa yang patut anda pertimbangkan ketika guna fasiliti awam?", ["Ikut suka hati", "Tengok orang lain buat", "Tak payah fikir", "Common sense"], 3],
	["Apakah contoh terbaik ketika menggunakan tandas awam?", ["Beratur, jaga bersih, jangan rosak fasiliti", "Pintas barisan kalau terdesak", "Conteng dinding sebagai kenangan", "Biarkan lantai basah"], 0],
	["Apa tindakan anda bila nampak orang rosakkan fasiliti awam?", ["Tidak ambil endah", "Rekod dan viralkan", "Lapor kepada pihak berkuasa", "Lapor kepada Tuhan"], 2],
]
const MACHINE := Rect2(590, 170, 320, 300)
const SLOT_Y := 330.0
const SLOT_L := 606.0
const SLOT_R := 894.0
const CW := 100.0
const CH := 66.0
const CARD_Y := SLOT_Y - 46.0
const MIN_T := 0.35
const MAX_T := 0.9
const STALL := Rect2(330, 240, 120, 240)
const METAL := Color(0.2, 0.55, 0.62)
const HELP := "Seret kad dari kiri ke kanan melalui slot. Ikut jalur hijau: jangan terlalu laju, jangan terlalu lambat."

var phase := 0
var q := 0
var correct := 0
var card_x := SLOT_L - 190.0
var grab_dx := 0.0
var swiping := false
var moving := false
var swipe_t0 := 0.0
var lock := true
var sc_text := "TAP KAD"
var sc_sub := "Letak kad pada pembaca"
var sc_state := 0
var dlg: DialogueBox
var avatar: AvatarView
var seq_t := 0.0
var shower_t := 0.0
var door_open := 0.0
var t := 0.0
var steam: Array[Dictionary] = []


func _build() -> void:
	station_id = "lrt"
	time_limit = 0.0
	active = false
	Sfx.play_music("lrt", -10.0)
	bg.color = Color(0.1, 0.03, 0.12)
	add_backdrop("res://assets/lrt_bg.png")
	body.visible = false
	var panel := Ui.panel(self, Rect2(556, 10, 388, 474), Ui.PINK)
	move_child(panel, 2)
	title.text = "LRT"
	title.position = Vector2(556, 18)
	title.custom_minimum_size.x = 388
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Ui.ORANGE)
	title.add_theme_color_override("font_outline_color", Ui.INK)
	title.add_theme_constant_override("outline_size", 8)
	Ui.label(self, "Swipe kad, jawab soalan, lepas tu mandi", Vector2(556, 62), 14, Ui.PINK, 388)
	Ui.rule(self, Vector2(574, 90), 352, Ui.PINK)
	status.position = Vector2(574, 98)
	status.custom_minimum_size.x = 352
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Ui.CREAM)
	status.text = HELP

	var back := Overlay.new()
	back.painter = _paint_stall_back
	back.z_index = 1
	add_child(back)
	avatar = AvatarView.new()
	avatar.position = Vector2(140, 480)
	avatar.scale = Vector2(1.4, 1.4)
	avatar.visible = false
	avatar.z_index = 7
	add_child(avatar)
	var front := Overlay.new()
	front.painter = _paint_stall_front
	front.z_index = 6
	add_child(front)
	var mach := Overlay.new()
	mach.painter = _paint_machine
	mach.z_index = 2
	add_child(mach)

	dlg = DialogueBox.new()
	dlg.z_index = 20
	add_child(dlg)

	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func(): Sfx.play("whoosh", -6.0))
	tw.tween_property(self, "card_x", SLOT_L, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): lock = false)


func _input(event: InputEvent) -> void:
	if phase != 0 or done or lock:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Rect2(card_x, CARD_Y, CW, CH).grow(24).has_point(event.position):
			swiping = true
			moving = false
			grab_dx = event.position.x - card_x
			Sfx.play("swipe", -4.0)
			sc_state = 0
			sc_text = "BACA KAD..."
			sc_sub = "Teruskan seret"
		elif not event.pressed and swiping:
			swiping = false
			if moving:
				_judge(0.0, false)
			else:
				_reset_card(0.2)
	elif event is InputEventMouseMotion and swiping:
		card_x = clampf(event.position.x - grab_dx, SLOT_L, SLOT_R - CW)
		if not moving and card_x > SLOT_L + 6.0:
			moving = true
			swipe_t0 = Time.get_ticks_msec() / 1000.0
		if moving and card_x >= SLOT_R - CW - 3.0:
			swiping = false
			_judge(Time.get_ticks_msec() / 1000.0 - swipe_t0, true)


func _reset_card(dur: float) -> void:
	create_tween().tween_property(self, "card_x", SLOT_L, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	sc_state = 0
	sc_text = "TAP KAD"
	sc_sub = "Letak kad pada pembaca"


func _judge(dt: float, reached: bool) -> void:
	var msg := ""
	var sub := ""
	if not reached:
		msg = "GAGAL: kad tak sampai hujung"
		sub = "TAK SAMPAI"
	elif dt < MIN_T:
		msg = "GAGAL: terlalu laju"
		sub = "TERLALU LAJU"
	elif dt > MAX_T:
		msg = "GAGAL: terlalu lambat"
		sub = "TERLALU LAMBAT"
	if msg == "":
		sc_state = 1
		sc_text = "SUCCESS"
		sc_sub = "Sila masuk"
		Sfx.play("beep")
		Sfx.play("success")
		status.text = "Kad berjaya! Staf kaunter ada soalan..."
		phase = 1
		await get_tree().create_timer(1.1).timeout
		_start_questions()
	else:
		sc_state = 2
		sc_text = "GAGAL"
		sc_sub = sub
		lock = true
		GameState.add_spread(1.5)
		Sfx.play("fail", -4.0)
		status.text = msg + ". Cuba lagi."
		create_tween().tween_property(self, "card_x", SLOT_L, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		await get_tree().create_timer(1.0).timeout
		if phase == 0:
			lock = false
			sc_state = 0
			sc_text = "TAP KAD"
			sc_sub = "Letak kad pada pembaca"
			status.text = HELP


func _start_questions() -> void:
	phase = 2
	status.text = ""
	dlg.open("Staf Kaunter", load("res://assets/staff_portrait.png"))
	await dlg.say("Eh, kau. Muka macam orang tak mandi tiga hari.")
	await dlg.say("Nak masuk tandas LRT? Jawab dulu %d soalan kebersihan. Setiap jawapan betul, aku bagi satu kuman. Tekan A-D atau klik." % QUESTIONS.size())
	for i in QUESTIONS.size():
		var d: Array = QUESTIONS[i]
		var pick: int = await dlg.ask("(%d/%d)  %s" % [i + 1, QUESTIONS.size(), d[0]], d[1])
		if d[2] == pick:
			correct += 1
			GameState.kuman += 1
			Sfx.play("coin")
			await dlg.say("Hmm, boleh tahan. +1 kuman.")
		else:
			Sfx.play("fail", -6.0)
			GameState.add_spread(3.0)
			await dlg.say("...Betul ke jawapan tu? Takpelah.")
	await dlg.say("Betul %d daripada %d. Dah, pergi mandi. Jangan lama-lama." % [correct, QUESTIONS.size()])
	dlg.close()
	phase = 3
	seq_t = 0.0
	avatar.visible = true
	sc_state = 1
	sc_text = "SILA MASUK"
	sc_sub = "Tandas LRT kosong"
	status.text = "Boy pergi ke tandas LRT..."


func _tick(delta: float) -> void:
	t += delta
	for s in steam:
		s["age"] += delta
	steam = steam.filter(func(s): return s["age"] < 1.6)
	if phase == 3:
		seq_t += delta
		var hop := absf(sin(seq_t * 10.0)) * 4.0 if (seq_t < 0.9 or (seq_t > 1.7 and seq_t < 2.4)) else 0.0
		if seq_t < 0.9:
			avatar.position.x = lerpf(140.0, 295.0, seq_t / 0.9)
		elif seq_t < 1.7:
			avatar.position.x = 295.0
			if door_open == 0.0:
				Sfx.play("whoosh", -4.0)
			door_open = clampf((seq_t - 0.9) / 0.7, 0.01, 1.0)
		elif seq_t < 2.4:
			avatar.position.x = lerpf(295.0, 390.0, (seq_t - 1.7) / 0.7)
			if seq_t > 2.0:
				avatar.z_index = 3
		elif seq_t < 3.1:
			avatar.position.x = 390.0
			door_open = 1.0 - clampf((seq_t - 2.4) / 0.6, 0.0, 1.0)
		else:
			door_open = 0.0
			phase = 4
			shower_t = 0.0
			Sfx.play("click")
			avatar.set_showering(true)
			Sfx.loop("water_loop")
			sc_text = "MANDI..."
			sc_sub = "Pintu dikunci"
			sc_state = 3
			status.text = "Boy mandi di LRT..."
		avatar.position.y = 480.0 - hop
	elif phase == 4:
		shower_t += delta
		if randf() < delta * 10.0:
			steam.append({"x": STALL.position.x + randf() * STALL.size.x, "age": 0.0})
		for i in PARTS.size():
			progress[i] = minf(1.0, shower_t / 4.0)
		if shower_t >= 4.0:
			phase = 5
			seq_t = 0.0
			avatar.set_showering(false)
			Sfx.stop_loop("water_loop")
			sc_text = "SIAP"
			sc_sub = "Bersih!"
			sc_state = 1
			status.text = "Segar! Boy keluar tandas."
	elif phase == 5:
		seq_t += delta
		if seq_t < 0.1:
			Sfx.play("whoosh", -4.0)
		door_open = clampf(seq_t / 0.7, 0.01, 1.0)
		if seq_t >= 1.5:
			done = true
			GameState.finish_station("lrt", clampf(0.4 + correct * 0.1, 0.4, 1.0))


func _paint_stall_back(o: Overlay) -> void:
	if phase < 3:
		return
	var r := STALL
	o.draw_rect(r, Color(0.16, 0.21, 0.27))
	for i in range(1, 4):
		o.draw_line(Vector2(r.position.x + i * 30.0, r.position.y), Vector2(r.position.x + i * 30.0, r.end.y), Color(0.1, 0.14, 0.2), 2.0)
	for i in range(1, 8):
		o.draw_line(Vector2(r.position.x, r.position.y + i * 30.0), Vector2(r.end.x, r.position.y + i * 30.0), Color(0.1, 0.14, 0.2), 2.0)
	o.draw_rect(Rect2(r.position.x, r.end.y - 22, r.size.x, 22), Color(0.26, 0.3, 0.34))
	o.draw_style_box(Ui.box(Color(0.92, 0.94, 0.96), Ui.INK, 8, 2), Rect2(r.end.x - 44, r.end.y - 56, 34, 34))
	o.draw_style_box(Ui.box(Color(0.85, 0.88, 0.92), Ui.INK, 4, 2), Rect2(r.end.x - 42, r.end.y - 96, 30, 38))
	var hx := r.position.x + 40.0
	o.draw_line(Vector2(hx, r.position.y), Vector2(hx, r.position.y + 28), Color(0.7, 0.72, 0.76), 4.0)
	o.draw_circle(Vector2(hx, r.position.y + 32), 13.0, Ui.INK)
	o.draw_circle(Vector2(hx, r.position.y + 32), 11.0, Color(0.75, 0.78, 0.82))
	if phase == 4:
		for i in 14:
			var x := hx - 10.0 + fmod(i * 7.3, 20.0)
			var y := r.position.y + 44.0 + fmod(t * 380.0 + i * 31.0, r.size.y - 70.0)
			o.draw_line(Vector2(x, y), Vector2(x - 1.5, y + 9.0), Color(0.6, 0.88, 1.0, 0.8), 2.0)


func _paint_stall_front(o: Overlay) -> void:
	if phase < 3:
		return
	var r := STALL
	var x0 := r.position.x
	var y0 := r.position.y
	var y1 := r.end.y
	var dark := Color(0.12, 0.2, 0.26)
	o.draw_rect(Rect2(x0 - 12, y0 - 26, 12, r.size.y + 26), dark)
	o.draw_rect(Rect2(r.end.x, y0 - 26, 12, r.size.y + 26), dark)
	o.draw_style_box(Ui.box(dark, Ui.INK, 4, 3), Rect2(x0 - 12, y0 - 40, r.size.x + 24, 30))
	Ui.text(o, Vector2(x0 + 4, y0 - 19), "TANDAS", 15, Color(1.0, 0.95, 0.85), 3)
	var occupied := door_open < 0.05 and phase >= 3 and seq_t > 2.4 or phase == 4
	o.draw_circle(Vector2(r.end.x - 14, y0 - 25), 6.0, Color(1.0, 0.2, 0.25) if occupied else Color(0.25, 1.0, 0.45))
	var dw := r.size.x * (1.0 - door_open * 0.8)
	var sk := door_open * 20.0
	var pts := PackedVector2Array([Vector2(x0, y0), Vector2(x0 + dw, y0 + sk), Vector2(x0 + dw, y1 - 6 - sk), Vector2(x0, y1 - 6)])
	var face := Color(METAL.r, METAL.g, METAL.b, 0.82)
	o.draw_colored_polygon(pts, face)
	for i in range(1, 9):
		var f := i / 9.0
		var ya := lerpf(y0, y1 - 6, f)
		var yb := lerpf(y0 + sk, y1 - 6 - sk, f)
		o.draw_line(Vector2(x0 + 4, ya), Vector2(x0 + dw - 4, yb), Color(0.1, 0.3, 0.36, 0.6), 3.0)
		o.draw_line(Vector2(x0 + 4, ya + 3), Vector2(x0 + dw - 4, yb + 3), Color(0.7, 0.95, 1.0, 0.18), 1.5)
	o.draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[3], pts[0]]), Ui.INK, 3.0)
	var hy := lerpf(y0 + sk, y1 - 6 - sk, 0.5) + 8.0
	o.draw_circle(Vector2(x0 + dw - 12, hy), 5.0, Color(0.95, 0.85, 0.4))
	o.draw_rect(Rect2(x0 + dw - 22, hy - 24, 14, 8), Color(1.0, 0.2, 0.25) if occupied else Color(0.25, 1.0, 0.45))
	for s in steam:
		var a: float = s["age"]
		var k := 1.0 - a / 1.6
		o.draw_circle(Vector2(s["x"], y0 + 20.0 - a * 22.0), 14.0 + a * 12.0, Color(0.95, 0.98, 1.0, 0.16 * k))


func _paint_machine(o: Overlay) -> void:
	var m := MACHINE
	o.draw_style_box(Ui.box(Color(0.14, 0.1, 0.24), Color(0.5, 0.4, 0.8), 14, 4), m)
	o.draw_rect(Rect2(m.position.x + 14, m.position.y + 6, m.size.x - 28, 4), Color(1, 1, 1, 0.12))
	Ui.text(o, Vector2(m.position.x + 16, m.position.y + 16), "KAD LRT", 11, Color(0.7, 0.65, 0.95), 0)
	var sr := Rect2(m.position.x + 20, m.position.y + 24, m.size.x - 40, 74)
	var fill := Color(0.04, 0.14, 0.2)
	var edge := Color(0.2, 0.8, 1.0)
	var tcol := Color(0.6, 0.95, 1.0)
	match sc_state:
		1:
			fill = Color(0.03, 0.3, 0.12)
			edge = Ui.GREEN
			tcol = Color(0.7, 1.0, 0.75)
		2:
			fill = Color(0.4, 0.04, 0.08)
			edge = Color(1.0, 0.3, 0.3)
			tcol = Color(1.0, 0.75, 0.75)
		3:
			fill = Color(0.03, 0.12, 0.3)
			edge = Ui.WATER
	o.draw_style_box(Ui.box(fill, edge, 8, 3), sr)
	var pulse := 0.75 + 0.25 * sin(t * 5.0) if sc_state == 0 else 1.0
	var fs := 32
	var tw := Ui.text_width(sc_text, fs)
	Ui.text(o, Vector2(sr.position.x + (sr.size.x - tw) / 2.0, sr.position.y + 40), sc_text, fs, Color(tcol.r, tcol.g, tcol.b, pulse), 4)
	var sw := Ui.text_width(sc_sub, 12)
	Ui.text(o, Vector2(sr.position.x + (sr.size.x - sw) / 2.0, sr.position.y + 62), sc_sub, 12, Color(tcol.r, tcol.g, tcol.b, 0.8), 0)
	for i in range(0, int(sr.size.y), 4):
		o.draw_line(Vector2(sr.position.x + 3, sr.position.y + i), Vector2(sr.end.x - 3, sr.position.y + i), Color(0, 0, 0, 0.14), 1.0)
	var lx := m.position.x + m.size.x / 2.0
	var blink := int(t * 3.0) % 2 == 0
	var leds := [
		[Vector2(lx - 40, 270), Color(1.0, 0.2, 0.25), sc_state == 2],
		[Vector2(lx, 270), Color(1.0, 0.75, 0.15), (sc_state == 0 and blink) or sc_state == 3],
		[Vector2(lx + 40, 270), Color(0.25, 1.0, 0.45), sc_state == 1],
	]
	for l in leds:
		var c: Vector2 = l[0]
		var col: Color = l[1]
		o.draw_circle(c, 9.0, Ui.INK)
		o.draw_circle(c, 7.0, col if l[2] else col.darkened(0.75))
		if l[2]:
			o.draw_circle(c, 13.0, Color(col.r, col.g, col.b, 0.25))
	o.draw_rect(Rect2(SLOT_L - 6, SLOT_Y - 8, SLOT_R - SLOT_L + 12, 20), Color(0.03, 0.02, 0.06))
	var cy := CARD_Y
	var cx := card_x
	o.draw_style_box(Ui.box(Color(0, 0, 0, 0.3), Color(0, 0, 0, 0), 8, 0), Rect2(cx + 4, cy + 6, CW, CH))
	o.draw_style_box(Ui.box(Color(0.98, 0.78, 0.2), Ui.INK, 8, 3), Rect2(cx, cy, CW, CH))
	o.draw_rect(Rect2(cx + 4, cy + 10, CW - 8, 10), Color(0.25, 0.1, 0.05))
	o.draw_style_box(Ui.box(Color(0.9, 0.82, 0.55), Color(0.55, 0.4, 0.1), 3, 1), Rect2(cx + 10, cy + 26, 22, 17))
	o.draw_line(Vector2(cx + 10, cy + 34), Vector2(cx + 32, cy + 34), Color(0.55, 0.4, 0.1), 1.0)
	Ui.text(o, Vector2(cx + 40, cy + 40), "KAD", 14, Ui.INK, 0)
	Ui.text(o, Vector2(cx + 40, cy + 54), "RAPID", 9, Color(0.5, 0.2, 0.1), 0)
	o.draw_style_box(Ui.box(Color(0.2, 0.17, 0.3), Color(0.55, 0.45, 0.85), 5, 2), Rect2(SLOT_L - 6, SLOT_Y, SLOT_R - SLOT_L + 12, 22))
	o.draw_rect(Rect2(SLOT_L, SLOT_Y + 3, SLOT_R - SLOT_L, 2), Color(1, 1, 1, 0.2))
	if phase >= 3:
		for i in PARTS.size():
			var y := 372.0 + i * 24.0
			Ui.text(o, Vector2(SLOT_L, y + 13), PARTS[i], 13, Ui.CREAM, 3)
			o.draw_rect(Rect2(SLOT_L + 80, y + 2, 200, 12), Color(0, 0, 0, 0.55))
			o.draw_rect(Rect2(SLOT_L + 80, y + 2, 200.0 * progress[i], 12), Ui.WATER)
		return
	Ui.text(o, Vector2(SLOT_L, 372), "KELAJUAN SWIPE", 11, Ui.ORANGE, 0)
	var tr := Rect2(SLOT_L, 380, SLOT_R - SLOT_L, 16)
	o.draw_style_box(Ui.box(Color(0.05, 0.02, 0.1), Color(0.5, 0.4, 0.8), 6, 2), tr)
	var span := SLOT_R - CW - SLOT_L
	if moving and swiping:
		var e := Time.get_ticks_msec() / 1000.0 - swipe_t0
		var a := clampf(e / MAX_T, 0.0, 1.0)
		var b := clampf(e / MIN_T, 0.0, 1.0)
		o.draw_rect(Rect2(SLOT_L + 4 + a * (tr.size.x - 8), 383, maxf(2.0, (b - a) * (tr.size.x - 8)), 10), Color(0.25, 1.0, 0.45, 0.65))
		var prog := (card_x - SLOT_L) / span
		var ok := prog >= a - 0.02 and prog <= b + 0.02
		o.draw_rect(Rect2(SLOT_L + 4 + prog * (tr.size.x - 8) - 2, 377, 4, 22), Color.WHITE if ok else Color(1.0, 0.35, 0.35))
		var hint := "OK, kekalkan!" if ok else ("Laju sikit!" if prog < a else "Perlahan sikit!")
		Ui.text(o, Vector2(SLOT_L, 420), hint, 16, Ui.GREEN if ok else Color(1.0, 0.5, 0.5), 4)
	else:
		for i in 4:
			var ax := SLOT_L + 30.0 + fmod(i * 60.0 + t * 80.0, tr.size.x - 50.0)
			Ui.text(o, Vector2(ax, 393), ">", 14, Color(0.7, 0.6, 1.0, 0.6), 0)
		Ui.text(o, Vector2(SLOT_L, 420), "Tahan kad & seret ke kanan", 14, Ui.CREAM, 3)
