extends ShowerBase
# R&R: tahan mengantuk. Boy nods off. Tap SPACE/click when the white line is inside a green zone = tampar air kat muka.
# Miss = station failed, retry from 0. 5 hits -> shower -> 5 kuman tokens.

const NEEDED := 5
const PANEL := Rect2(566, 14, 380, 482)
const TRACK := Rect2(24, 272, 332, 44)
const PINK := Color(1.0, 0.25, 0.55)
const ORANGE := Color(1.0, 0.72, 0.15)
const GREEN := Color(0.2, 0.92, 0.42)
const WATER := Color(0.5, 0.86, 1.0)
const INK := Color(0.1, 0.0, 0.13)
const FACE := Vector2(270, 300)
const POPS := ["SPLASH!", "SEJUK!", "SEGAR!", "MANTAP!", "CUSS!"]
const HELP := "Tekan SPACE atau klik bila garis putih berada dalam zon hijau. Tersasar = GAGAL, ulang dari awal."

var avatar: AvatarView
var backdrop: TextureRect
var dim := ColorRect.new()
var flash := ColorRect.new()
var panel := Panel.new()
var line := ColorRect.new()
var zones: Array[ColorRect] = []
var zone_ranges: Array[Vector2] = []
var drops: Array[Panel] = []
var sleep_fill := ColorRect.new()
var sleep_l: Label
var info_l: Label
var pop_l: Label
var fails_l: Label
var splash := CPUParticles2D.new()
var pos := 0.0
var dir := 1.0
var hits := 0
var fails := 0
var phase := 0
var shower_t := 0.0
var shake := 0.0
var t := 0.0


func _build() -> void:
	station_id = "rnr"
	time_limit = 0.0
	active = false
	bg.color = Color(0.1, 0.03, 0.12)
	backdrop = add_backdrop("res://assets/rnr_bg.png")
	for l in [title, status, body]:
		l.visible = false

	dim.size = Vector2(540, 540)
	dim.color = Color(0.05, 0.0, 0.12, 0.0)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	avatar = AvatarView.new()
	avatar.position = Vector2(270, 505)
	avatar.scale = Vector2(2.0, 2.0)
	add_child(avatar)
	avatar.nod = 0.55

	splash.position = FACE
	splash.one_shot = true
	splash.emitting = false
	splash.amount = 48
	splash.lifetime = 0.65
	splash.explosiveness = 1.0
	splash.direction = Vector2(0, -1)
	splash.spread = 180.0
	splash.gravity = Vector2(0, 750)
	splash.initial_velocity_min = 120.0
	splash.initial_velocity_max = 280.0
	splash.scale_amount_min = 3.0
	splash.scale_amount_max = 6.0
	splash.color = WATER
	add_child(splash)

	flash.size = Vector2(540, 540)
	flash.color = Color(0.7, 0.9, 1.0, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(flash)

	var strip := ColorRect.new()
	strip.position = Vector2(0, 508)
	strip.size = Vector2(960, 32)
	strip.color = Color(0.05, 0.0, 0.09, 0.88)
	strip.z_index = 20
	add_child(strip)
	hud.z_index = 21

	_build_panel()
	_reroll()


func _build_panel() -> void:
	panel.position = PANEL.position
	panel.size = PANEL.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.015, 0.14, 0.96)
	sb.set_border_width_all(4)
	sb.border_color = PINK
	sb.set_corner_radius_all(8)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 10
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	_lbl(panel, "R&R", Vector2(0, 8), 58, ORANGE)
	_lbl(panel, "TAHAN MENGANTUK!", Vector2(0, 80), 27, PINK)
	var rule := ColorRect.new()
	rule.color = PINK
	rule.position = Vector2(24, 122)
	rule.size = Vector2(332, 3)
	panel.add_child(rule)

	info_l = _lbl(panel, HELP, Vector2(24, 132), 16, Color(1, 0.95, 0.85), 332.0)
	info_l.size.y = 64
	info_l.add_theme_constant_override("outline_size", 3)

	sleep_l = _lbl(panel, "KANTUK", Vector2(24, 204), 16, Color(1, 0.9, 0.7), 332.0, false)
	var meter := Panel.new()
	meter.position = Vector2(24, 232)
	meter.size = Vector2(332, 18)
	meter.add_theme_stylebox_override("panel", _box(Color(0.05, 0.02, 0.1), INK, 4))
	panel.add_child(meter)
	sleep_fill.position = Vector2(3, 3)
	sleep_fill.size = Vector2(0, 12)
	meter.add_child(sleep_fill)

	var track := Panel.new()
	track.position = TRACK.position - Vector2(4, 4)
	track.size = TRACK.size + Vector2(8, 8)
	track.add_theme_stylebox_override("panel", _box(Color(0.04, 0.015, 0.09), Color(0.45, 0.85, 1.0), 6))
	panel.add_child(track)
	for i in 3:
		var z := ColorRect.new()
		z.color = GREEN
		z.position = TRACK.position
		z.size = Vector2(0, TRACK.size.y)
		panel.add_child(z)
		var glow := ColorRect.new()
		glow.color = Color(0.2, 1.0, 0.5, 0.28)
		glow.show_behind_parent = true
		glow.position = Vector2(-4, -4)
		z.add_child(glow)
		zones.append(z)
		zone_ranges.append(Vector2.ZERO)
	line.color = Color.WHITE
	line.size = Vector2(5, TRACK.size.y + 16)
	panel.add_child(line)
	var lglow := ColorRect.new()
	lglow.color = Color(1, 1, 1, 0.3)
	lglow.show_behind_parent = true
	lglow.position = Vector2(-5, 0)
	lglow.size = Vector2(15, line.size.y)
	line.add_child(lglow)

	pop_l = _lbl(panel, "", Vector2(0, 326), 32, WATER)
	pop_l.pivot_offset = Vector2(190, 22)
	pop_l.modulate.a = 0.0

	_lbl(panel, "AIR SEJUK", Vector2(24, 372), 16, Color(1, 0.9, 0.7), 332.0, false)
	for i in NEEDED:
		var d := Panel.new()
		d.size = Vector2(34, 34)
		d.position = Vector2(77 + i * 48, 398)
		d.add_theme_stylebox_override("panel", _drop_style(false))
		panel.add_child(d)
		drops.append(d)
	fails_l = _lbl(panel, "", Vector2(0, 446), 18, Color(1, 0.7, 0.75))


func _lbl(parent: Node, text: String, p: Vector2, fs: int, col: Color, w := 380.0, center := true) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = w
	l.text = text
	l.position = p
	l.size = Vector2(w, fs * 1.4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", maxi(2, fs / 6))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


func _box(fill: Color, border: Color, radius: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_border_width_all(3)
	s.border_color = border
	s.set_corner_radius_all(radius)
	return s


func _drop_style(on: bool) -> StyleBoxFlat:
	var s := _box(WATER if on else Color(0.12, 0.06, 0.2), INK, 17)
	if on:
		s.shadow_color = Color(0.5, 0.86, 1.0, 0.6)
		s.shadow_size = 8
	return s


func _set_drops() -> void:
	for i in drops.size():
		drops[i].add_theme_stylebox_override("panel", _drop_style(i < hits))


func _pop(text: String, col: Color) -> void:
	pop_l.text = text
	pop_l.add_theme_color_override("font_color", col)
	pop_l.modulate.a = 1.0
	pop_l.scale = Vector2(1.5, 1.5)
	var tw := create_tween()
	tw.tween_property(pop_l, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.5)
	tw.tween_property(pop_l, "modulate:a", 0.0, 0.4)


func _flash(col: Color) -> void:
	flash.color = col
	create_tween().tween_property(flash, "color:a", 0.0, 0.35)


func _info(text: String, col: Color) -> void:
	info_l.text = text
	info_l.add_theme_color_override("font_color", col)


func _reroll() -> void:
	var starts := [0.06, 0.38, 0.7]
	for i in zones.size():
		var w := randf_range(0.1, 0.16)
		var s: float = starts[i] + randf_range(0.0, 0.1)
		zone_ranges[i] = Vector2(s, s + w)
		zones[i].position.x = TRACK.position.x + s * TRACK.size.x
		zones[i].size.x = w * TRACK.size.x
		(zones[i].get_child(0) as ColorRect).size = zones[i].size + Vector2(8, 8)


func _input(event: InputEvent) -> void:
	if done or phase != 0:
		return
	var tap := false
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		tap = true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		tap = true
	if tap:
		_tap()


func _tap() -> void:
	var ok := false
	for r in zone_ranges:
		if pos >= r.x and pos <= r.y:
			ok = true
	if ok:
		hits += 1
		avatar.slap()
		Sfx.play("slap")
		avatar.say("Cuss! Sejuk!")
		avatar.nod = maxf(0.05, 0.55 - hits * 0.1)
		_set_drops()
		_pop(POPS[randi() % POPS.size()], WATER)
		_flash(Color(0.7, 0.9, 1.0, 0.55))
		splash.restart()
		_info(HELP, Color(1, 0.95, 0.85))
		_reroll()
		if hits >= NEEDED:
			phase = 1
			shower_t = 0.0
			avatar.nod = 0.0
			avatar.set_showering(true)
			Sfx.loop("water_loop")
			Sfx.play("success")
			_pop("SEGAR!  +5 KUMAN", ORANGE)
			_info("Dah segar! Boy mandi di R&R...", Color(0.6, 1.0, 0.7))
	else:
		fails += 1
		hits = 0
		_set_drops()
		Sfx.play("fail")
		avatar.nod = 0.95
		avatar.say("Zzz... tertidur")
		shake = 0.4
		_flash(Color(0.9, 0.1, 0.2, 0.5))
		_pop("TERTIDUR!", Color(1.0, 0.3, 0.35))
		_info("GAGAL! Tersasar zon hijau, boy tertidur. Cuba lagi dari awal.", Color(1.0, 0.45, 0.5))
		_reroll()


func _tick(delta: float) -> void:
	t += delta
	fails_l.text = "Gagal: %d" % fails
	var k := clampf(avatar.nod / 0.95, 0.0, 1.0)
	sleep_fill.size.x = 326.0 * k
	sleep_fill.color = GREEN.lerp(ORANGE, clampf(k * 2.0, 0.0, 1.0)).lerp(Color(1.0, 0.2, 0.25), clampf(k * 2.0 - 1.0, 0.0, 1.0))
	sleep_l.text = "KANTUK   Zzz..." if k > 0.75 else "KANTUK"
	backdrop.modulate = Color.WHITE.lerp(Color(0.5, 0.5, 0.72), k)
	dim.color.a = k * 0.4
	for i in zones.size():
		zones[i].modulate.a = 0.82 + 0.18 * sin(t * 6.0 + i)
	if shake > 0.0:
		shake = maxf(0.0, shake - delta)
		position = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake * 22.0
	else:
		position = Vector2.ZERO
	if phase == 0:
		var speed := 0.55 + hits * 0.12
		pos += dir * speed * delta
		if pos >= 1.0:
			pos = 1.0
			dir = -1.0
		elif pos <= 0.0:
			pos = 0.0
			dir = 1.0
		line.position = Vector2(TRACK.position.x + pos * TRACK.size.x - 2.5, TRACK.position.y - 8)
		avatar.nod = minf(0.95, avatar.nod + delta * 0.03)
	else:
		shower_t += delta
		if shower_t > 4.0:
			done = true
			Sfx.stop_loop("water_loop")
			Sfx.play("coin")
			GameState.kuman += 5
			GameState.finish_station("rnr", clampf(1.0 - fails * 0.15, 0.4, 1.0))
