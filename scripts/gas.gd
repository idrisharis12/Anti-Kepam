extends ShowerBase
# Gas station: scrub graffiti and bacteria off the toilet (mirror, sink, toilet, partition) like an eraser.
# The clean room is underneath, so erasing reveals it. Soap = bigger eraser. Knocks: press E ("Kejap!").

const TARGETS := [
	["Cermin & Sinki", Rect2(0, 0, 184, 400)],
	["Dinding", Rect2(184, 0, 208, 236)],
	["Jamban", Rect2(184, 236, 208, 164)],
	["Lantai", Rect2(0, 400, 392, 94)],
	["Partisyen", Rect2(392, 0, 148, 494)],
]
const CELL_PX := 6
const TOTAL_KNOCKS := 5
const MAX_MISSES := 3
const HELP := "SERET mouse = mop vandalisme & kuman. Sabun = mop lebih besar. Ada orang ketuk: tekan E!"
const MUD := [Color(0.35, 0.4, 0.1), Color(0.45, 0.3, 0.12), Color(0.25, 0.35, 0.15), Color(0.4, 0.12, 0.12)]
const DARK := Color(0.1, 0.0, 0.13, 0.9)

var layers: Array[Dictionary] = []
var avatar: AvatarView
var cleaned := 0
var phase := 0
var phase_t := 0.0
var knocks_done := 0
var misses := 0
var next_knock := 6.0
var knock_wait := 0.0
var knocking := false
var failed := false
var scrub: CPUParticles2D
var scrub_t := 0.0
var sparkles: Array[Dictionary] = []
var t := 0.0
var dirty_img: Image
var sweep_cleaned := 0
var combo_bonus := 0.0


func _build() -> void:
	station_id = "gas"
	NpcChat.show_on(self, "gas_attendant")
	time_limit = 0.0
	active = false
	bg.color = Color(0.1, 0.03, 0.12)
	add_backdrop("res://assets/gas_clean_bg.png")
	dirty_img = (load("res://assets/gas_dirty_bg.png") as Texture2D).get_image()
	if dirty_img.is_compressed():
		dirty_img.decompress()
	dirty_img.convert(Image.FORMAT_RGBA8)
	body.visible = false
	var panel := Ui.panel(self, Rect2(556, 10, 388, 474), Ui.PINK)
	move_child(panel, 2)
	title.text = "GAS STATION"
	title.position = Vector2(556, 18)
	title.custom_minimum_size.x = 388
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Ui.ORANGE)
	title.add_theme_color_override("font_outline_color", Ui.INK)
	title.add_theme_constant_override("outline_size", 8)
	Ui.label(self, "Tandas awam dah kena vandalisme!", Vector2(556, 62), 14, Ui.PINK, 388)
	Ui.rule(self, Vector2(574, 90), 352, Ui.PINK)
	status.position = Vector2(574, 98)
	status.custom_minimum_size.x = 352
	status.add_theme_font_size_override("font_size", 14)
	status.add_theme_color_override("font_color", Ui.CREAM)
	status.text = HELP
	avatar = AvatarView.new()
	avatar.position = Vector2(850, 480)
	avatar.scale = Vector2(1.15, 1.15)
	avatar.dirt = 0.6
	add_child(avatar)
	scrub = CPUParticles2D.new()
	scrub.emitting = false
	scrub.amount = 24
	scrub.lifetime = 0.55
	scrub.direction = Vector2(0, -1)
	scrub.spread = 60.0
	scrub.initial_velocity_min = 30.0
	scrub.initial_velocity_max = 80.0
	scrub.gravity = Vector2(0, 40)
	scrub.scale_amount_min = 2.0
	scrub.scale_amount_max = 4.5
	scrub.color = Color(0.85, 0.97, 1.0, 0.9)
	scrub.z_index = 5
	add_child(scrub)
	for tg in TARGETS:
		_make_layer(tg[0], tg[1])
	var ov := Overlay.new()
	ov.painter = _paint
	ov.z_index = 6
	add_child(ov)


func _stamp(img: Image, cx: float, cy: float, rad: float, c: Color, soft := false) -> void:
	var w := img.get_width()
	var h := img.get_height()
	for y in range(maxi(0, int(cy - rad)), mini(h, int(cy + rad) + 1)):
		for x in range(maxi(0, int(cx - rad)), mini(w, int(cx + rad) + 1)):
			var d := Vector2(x - cx, y - cy).length()
			if d <= rad:
				var col := c
				if soft:
					col.a = c.a * (1.0 - d / rad)
				img.set_pixel(x, y, img.get_pixel(x, y).blend(col))


func _germ_px(img: Image, cx: float, cy: float, r: float) -> void:
	var c: Color = MUD[randi() % MUD.size()]
	_stamp(img, cx, cy, r + 1.5, DARK)
	_stamp(img, cx, cy, r, c)
	_stamp(img, cx - r * 0.3, cy - r * 0.35, r * 0.3, c.lightened(0.25))
	for i in 6:
		var a := TAU * i / 6.0
		_stamp(img, cx + cos(a) * (r + 2.5), cy + sin(a) * (r + 2.5), 1.4, DARK)


func _make_layer(label: String, r: Rect2) -> void:
	var w := int(r.size.x)
	var h := int(r.size.y)
	var area := w * h
	var sc := dirty_img.get_width() / 540.0
	var x0 := clampi(int(r.position.x * sc), 0, dirty_img.get_width() - 2)
	var y0 := clampi(int(r.position.y * sc), 0, dirty_img.get_height() - 2)
	var x1 := clampi(int(r.end.x * sc), x0 + 1, dirty_img.get_width())
	var y1 := clampi(int(r.end.y * sc), y0 + 1, dirty_img.get_height())
	var img := dirty_img.get_region(Rect2i(x0, y0, x1 - x0, y1 - y0))
	img.resize(w, h, Image.INTERPOLATE_BILINEAR)
	for i in area / 6000 + 2:
		_germ_px(img, randf_range(10, w - 10), randf_range(10, h - 10), randf_range(4.0, 6.5))
	var tex := ImageTexture.create_from_image(img)
	var node := TextureRect.new()
	node.texture = tex
	node.position = r.position
	node.size = r.size
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	var gw := ceili(w / float(CELL_PX))
	var gh := ceili(h / float(CELL_PX))
	var grid := PackedByteArray()
	grid.resize(gw * gh)
	var need := 0
	for gy in gh:
		for gx in gw:
			var dirty := false
			for yy in range(gy * CELL_PX, mini(h, (gy + 1) * CELL_PX)):
				for xx in range(gx * CELL_PX, mini(w, (gx + 1) * CELL_PX)):
					if img.get_pixel(xx, yy).a > 0.2:
						dirty = true
			grid[gy * gw + gx] = 0 if dirty else 1
			if dirty:
				need += 1
	var germs: Array[Vector2] = []
	for i in 3:
		germs.append(Vector2(randf_range(10, w - 10), randf_range(10, h - 10)))
	layers.append({"name": label, "rect": r, "img": img, "tex": tex, "node": node, "grid": grid, "gw": gw, "gh": gh, "need": need, "left": need, "soapy": false, "clean": false, "germs": germs, "flash": 0.0})


func _erase(i: int, p: Vector2) -> void:
	var L: Dictionary = layers[i]
	if L["clean"]:
		return
	if not L["soapy"] and GameState.soap > 0:
		GameState.soap -= 1
		L["soapy"] = true
	var rad := (28 if L["soapy"] else 15) + 4 * GameState.upgrade_level("mop")
	var img: Image = L["img"]
	var local := p - (L["rect"] as Rect2).position
	for y in range(maxi(0, int(local.y) - rad), mini(img.get_height(), int(local.y) + rad)):
		for x in range(maxi(0, int(local.x) - rad), mini(img.get_width(), int(local.x) + rad)):
			if Vector2(x - local.x, y - local.y).length() <= rad:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	(L["tex"] as ImageTexture).update(img)
	scrub.position = p
	scrub_t = 0.1
	var grid: PackedByteArray = L["grid"]
	var gw: int = L["gw"]
	var cr := ceili(rad / float(CELL_PX))
	var gcx := int(local.x / CELL_PX)
	var gcy := int(local.y / CELL_PX)
	for gy in range(maxi(0, gcy - cr), mini(L["gh"], gcy + cr + 1)):
		for gx in range(maxi(0, gcx - cr), mini(gw, gcx + cr + 1)):
			if grid[gy * gw + gx] == 0 and Vector2(gx - gcx, gy - gcy).length() <= cr:
				grid[gy * gw + gx] = 1
				L["left"] -= 1
	L["grid"] = grid
	if L["left"] <= int(L["need"] * 0.03):
		L["clean"] = true
		L["flash"] = 1.0
		(L["node"] as TextureRect).visible = false
		cleaned += 1
		var rc: Rect2 = L["rect"]
		for k in 22:
			sparkles.append({"pos": rc.position + Vector2(randf() * rc.size.x, randf() * rc.size.y), "age": -randf() * 0.5})
		_start_shower()


func _start_shower() -> void:
	phase = 1
	phase_t = 0.0
	Sfx.loop("water_loop")
	Sfx.play("success")
	avatar.set_showering(true)
	avatar.dirt = maxf(0.0, avatar.dirt - 0.3)
	avatar.position = Vector2(272, 470)
	avatar.scale = Vector2(1.05, 1.05)
	avatar.z_index = 4
	status.text = "Berkilat! Bersih tanpa vandalisme & kuman. Boy mandi sekejap..."
	var per := 1.0 / TARGETS.size()
	for i in PARTS.size():
		progress[i] = minf(1.0, progress[i] + per)


func _input(event: InputEvent) -> void:
	if done or failed:
		return
	if event is InputEventMouseMotion and phase == 0 and (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
		for i in layers.size():
			if (layers[i]["rect"] as Rect2).grow(4).has_point(event.position):
				_erase(i, event.position)
				break
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		sweep_cleaned = 0
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E and knocking:
		knocking = false
		knocks_done += 1
		next_knock = 6.0
		avatar.say("Kejap!")
		Sfx.play("kejap")


func _tick(delta: float) -> void:
	t += delta
	scrub_t -= delta
	scrub.emitting = scrub_t > 0.0
	for s in sparkles:
		s["age"] += delta
	sparkles = sparkles.filter(func(s): return s["age"] < 0.8)
	for L in layers:
		L["flash"] = maxf(0.0, L["flash"] - delta * 1.6)
		if L["clean"] and randf() < delta * 2.0:
			var rc: Rect2 = L["rect"]
			sparkles.append({"pos": rc.position + Vector2(randf() * rc.size.x, randf() * rc.size.y), "age": 0.0})
	if failed:
		phase_t += delta
		if phase_t > 2.5:
			get_tree().reload_current_scene()
		return
	if phase == 1:
		phase_t += delta
		if phase_t > 2.2:
			avatar.set_showering(false)
			avatar.position = Vector2(850, 480)
			avatar.scale = Vector2(1.15, 1.15)
			avatar.z_index = 0
			Sfx.stop_loop("water_loop")
			if cleaned >= TARGETS.size():
				_finish_station()
			else:
				phase = 0
				status.text = HELP
	_knock_logic(delta)


func _heart(o: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	o.draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.58, col)
	o.draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.58, col)
	o.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.04, -r * 0.0), c + Vector2(r * 1.04, 0), c + Vector2(0, r * 1.1)]), col)


func _star(o: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array([c + Vector2(0, -r), c + Vector2(r * 0.18, -r * 0.18), c + Vector2(r, 0), c + Vector2(r * 0.18, r * 0.18), c + Vector2(0, r), c + Vector2(-r * 0.18, r * 0.18), c + Vector2(-r, 0), c + Vector2(-r * 0.18, -r * 0.18)])
	o.draw_colored_polygon(pts, col)


func _paint(o: Overlay) -> void:
	for L in layers:
		var rc: Rect2 = L["rect"]
		if L["flash"] > 0.0:
			o.draw_rect(rc, Color(1, 1, 1, L["flash"] * 0.7))
		if not L["clean"]:
			var img: Image = L["img"]
			var gi := 0
			for g in L["germs"]:
				var gp: Vector2 = g
				if img.get_pixel(clampi(int(gp.x), 0, img.get_width() - 1), clampi(int(gp.y), 0, img.get_height() - 1)).a > 0.1:
					var ep := rc.position + gp
					if fmod(t + gi * 1.7, 3.0) < 0.25:
						o.draw_circle(ep + Vector2(-2.5, 0), 1.8, Color.WHITE)
						o.draw_circle(ep + Vector2(2.5, 0), 1.8, Color.WHITE)
				gi += 1
	for s in sparkles:
		var a: float = s["age"]
		if a < 0.0:
			continue
		var k := 1.0 - a / 0.8
		_star(o, s["pos"], 3.0 + 7.0 * sin(PI * (1.0 - k)), Color(1.0, 1.0, 0.85, k))
	Ui.text(o, Vector2(574, 188), "VANDALISME & KUMAN", 13, Ui.ORANGE, 4)
	for i in layers.size():
		var L: Dictionary = layers[i]
		var y := 196.0 + i * 20.0
		var done_l: bool = L["clean"]
		o.draw_style_box(Ui.box(Color(0.0, 0.25, 0.1, 0.8) if done_l else Color(0.17, 0.05, 0.22), Ui.GREEN if done_l else Color(0.5, 0.2, 0.6), 6, 2), Rect2(574, y, 190, 17))
		if done_l:
			o.draw_line(Vector2(582, y + 9), Vector2(587, y + 14), Ui.GREEN, 3.0)
			o.draw_line(Vector2(587, y + 14), Vector2(596, y + 4), Ui.GREEN, 3.0)
		else:
			Ui.germ(o, Vector2(590, y + 9), 5.5, t + i)
		Ui.text(o, Vector2(606, y + 14), L["name"], 13, Color(0.7, 1.0, 0.75) if done_l else Ui.CREAM, 3)
		var frac := 1.0 if done_l else 1.0 - float(L["left"]) / maxf(1.0, float(L["need"]))
		o.draw_rect(Rect2(702, y + 4, 54, 9), Color(0, 0, 0, 0.5))
		o.draw_rect(Rect2(702, y + 4, 54 * frac, 9), Ui.GREEN if done_l else Ui.WATER)
	Ui.text(o, Vector2(574, 312), "KETUKAN PINTU", 13, Ui.ORANGE, 4)
	for i in TOTAL_KNOCKS:
		var c := Vector2(588 + i * 32, 334)
		var hit := i < knocks_done
		o.draw_circle(c, 12, Ui.INK)
		o.draw_circle(c, 10, Ui.GREEN.darkened(0.2) if hit else Color(0.25, 0.1, 0.3))
		if hit:
			o.draw_line(c + Vector2(-4, 0), c + Vector2(-1, 4), Color.WHITE, 2.5)
			o.draw_line(c + Vector2(-1, 4), c + Vector2(5, -4), Color.WHITE, 2.5)
	Ui.text(o, Vector2(574, 372), "PELUANG", 13, Ui.ORANGE, 4)
	for i in MAX_MISSES:
		var alive := i < MAX_MISSES - misses
		_heart(o, Vector2(590 + i * 34, 392), 10, Color(1.0, 0.25, 0.4) if alive else Color(0.3, 0.12, 0.2))
	if knocking:
		var pulse := 0.6 + 0.4 * sin(t * 16.0)
		o.draw_style_box(Ui.box(Color(0.7, 0.05, 0.1, pulse), Color(1, 0.8, 0.3), 8, 3), Rect2(574, 418, 180, 56))
		Ui.text(o, Vector2(584, 440), "TOK TOK TOK!", 18, Color.WHITE, 5)
		Ui.text(o, Vector2(584, 464), "Tekan E!", 14, Ui.ORANGE, 4)
		o.draw_rect(Rect2(660, 452, 88 * clampf(knock_wait / 3.0, 0.0, 1.0), 8), Ui.ORANGE)
	if phase == 0 and not failed:
		var m := o.get_global_mouse_position()
		if m.x < 545.0 and m.y < 494.0:
			var soapy := GameState.soap > 0
			for L in layers:
				if L["soapy"] and (L["rect"] as Rect2).grow(4).has_point(m):
					soapy = true
			_mop(o, m, soapy)


func _mop(o: CanvasItem, m: Vector2, soapy: bool) -> void:
	var down := Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	var ang := 0.35 + (sin(t * 32.0) * 0.28 if down else 0.0)
	var sx := 1.45 if soapy else 1.0
	var xf := Transform2D(ang, m)
	var hand := xf * Vector2(0, -92)
	var neck := xf * Vector2(0, -20)
	o.draw_line(neck, hand, Ui.INK, 8.0)
	o.draw_line(neck, hand, Color(0.75, 0.5, 0.2), 5.0)
	var hw := 15.0 * sx
	var head := PackedVector2Array([xf * Vector2(-hw * 0.5, -22), xf * Vector2(hw * 0.5, -22), xf * Vector2(hw, 6), xf * Vector2(-hw, 6)])
	o.draw_colored_polygon(head, Ui.INK)
	var col := Color(0.85, 0.92, 1.0) if soapy else Color(0.62, 0.55, 0.45)
	for i in 9:
		var fx := lerpf(-hw, hw, i / 8.0)
		var wob := sin(t * 20.0 + i) * (3.0 if down else 1.0)
		o.draw_line(xf * Vector2(fx * 0.55, -20), xf * Vector2(fx + wob, 10 + (i % 3) * 3), col.darkened(0.25 * (i % 2)), 3.5)
	o.draw_circle(xf * Vector2(0, -22), 6.0, Color(0.2, 0.55, 0.7))
	if soapy:
		for i in 5:
			var bp := xf * Vector2(sin(t * 3.0 + i * 1.9) * hw, 4.0 + cos(t * 2.0 + i) * 6.0)
			o.draw_circle(bp, 3.0 + (i % 3), Color(1, 1, 1, 0.75))
		var r := 28.0
		o.draw_arc(m, r, 0, TAU, 28, Color(1, 1, 1, 0.35), 1.5)


func _knock_logic(delta: float) -> void:
	if knocking:
		knock_wait -= delta
		status.text = "TOK TOK TOK! Tekan E jawab!"
		if knock_wait <= 0.0:
			knocking = false
			knocks_done += 1
			misses += 1
			next_knock = 6.0
			status.text = "Tak jawab! Orang marah."
			if misses >= MAX_MISSES:
				failed = true
				Sfx.stop_loop("water_loop")
				Sfx.play("fail")
				phase_t = 0.0
				avatar.set_showering(false)
				status.text = "GAGAL! 3 ketukan tak dijawab. Cuba lagi dari awal..."
				GameState.add_spread(6.0)
	elif knocks_done < TOTAL_KNOCKS:
		next_knock -= delta
		if next_knock <= 0.0:
			knocking = true
			Sfx.play("knock")
			knock_wait = 3.0


func _finish_station() -> void:
	done = true
	Sfx.stop_loop("water_loop")
	GameState.finish_station("gas", clampf(clampf(1.0 - misses * 0.2, 0.4, 1.0) + combo_bonus, 0.4, 1.0))


func _exit_tree() -> void:
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)
