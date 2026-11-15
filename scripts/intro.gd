extends Node2D
# Cinematic intro: rainy bedroom, WhatsApp breakup on the phone, caption bubble under the phone. ENTER skips.

const W := 960.0
const H := 540.0
const DIM := Color(0.85, 0.88, 1.0)
const PHONE_SIZE := Vector2(270, 396)
const PHONE_X := 345.0
const PHONE_Y := 52.0
const GREEN := Color(0.2, 0.92, 0.55)

var skipped := false
var t := 0.0
const GF_TEX := preload("res://assets/gf_portrait.png")
var face_g := 0.2
var sub_text := ""
var room: TextureRect
var rain_clip: Control
var drops: Array[ColorRect] = []
var phone: Panel
var chat: VBoxContainer
var glow: TextureRect
var badge: Panel
var typing_row: Control
var typing_dots: Control
var cap_panel: Panel
var caption: Label


func _ready() -> void:
	Sfx.play_music("intro")
	Sfx.loop("rain_loop", -10.0)
	_rect(Vector2.ZERO, Vector2(W, H), Color.BLACK, self)

	room = TextureRect.new()
	room.texture = load("res://assets/intro_bg.png")
	room.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	room.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	room.size = Vector2(W, W)
	room.position = Vector2(0, -250)
	room.pivot_offset = Vector2(516, 394)
	room.modulate = Color.BLACK
	add_child(room)

	rain_clip = Control.new()
	rain_clip.position = Vector2(623, 211)
	rain_clip.size = Vector2(225, 248)
	rain_clip.clip_contents = true
	rain_clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	room.add_child(rain_clip)
	for i in 45:
		var d := _rect(Vector2(randf() * 225.0, randf() * 248.0), Vector2(1.5, 14), Color(0.7, 0.8, 1.0, 0.35), rain_clip)
		drops.append(d)

	var grad := Gradient.new()
	grad.offsets = PackedFloat32Array([0.45, 1.0])
	grad.colors = PackedColorArray([Color(0, 0, 0, 0), Color(0, 0, 0, 0.92)])
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 512
	gt.height = 288
	var vig := TextureRect.new()
	vig.texture = gt
	vig.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	vig.size = Vector2(W, H)
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(vig)

	_rect(Vector2.ZERO, Vector2(W, 40), Color.BLACK, self)
	_rect(Vector2(0, H - 40), Vector2(W, 40), Color.BLACK, self)

	_build_phone()
	_build_caption()
	var hint := Ui.label(self, "ENTER: langkau", Vector2(760, 510), 13, Color(0.5, 0.5, 0.6), 180, false)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_run()


func _rect(pos: Vector2, size: Vector2, color: Color, parent: Node) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _build_caption() -> void:
	cap_panel = Panel.new()
	cap_panel.position = Vector2(130, 460)
	cap_panel.size = Vector2(700, 38)
	var sb := Ui.box(Color(0.08, 0.015, 0.14, 0.94), Ui.PINK, 19, 3)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 8
	cap_panel.add_theme_stylebox_override("panel", sb)
	cap_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cap_panel.modulate.a = 0.0
	add_child(cap_panel)
	caption = Ui.label(cap_panel, "", Vector2(0, 5), 20, Ui.CREAM, 700)
	caption.custom_minimum_size.x = 700


func _build_phone() -> void:
	var gg := Gradient.new()
	gg.offsets = PackedFloat32Array([0.0, 1.0])
	gg.colors = PackedColorArray([Color(0.2, 1.0, 0.6, 0.45), Color(0.2, 1.0, 0.6, 0.0)])
	var gtex := GradientTexture2D.new()
	gtex.gradient = gg
	gtex.fill = GradientTexture2D.FILL_RADIAL
	gtex.fill_from = Vector2(0.5, 0.5)
	gtex.fill_to = Vector2(1.0, 0.5)
	gtex.width = 256
	gtex.height = 256
	glow = TextureRect.new()
	glow.texture = gtex
	glow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glow.size = Vector2(560, 560)
	glow.position = Vector2(PHONE_X + PHONE_SIZE.x / 2.0 - 280.0, 570)
	glow.modulate.a = 0.0
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	phone = Panel.new()
	phone.size = PHONE_SIZE
	phone.position = Vector2(PHONE_X, 570)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.043, 0.078, 0.102)
	sb.set_corner_radius_all(30)
	sb.set_border_width_all(6)
	sb.border_color = Color(0.1, 0.1, 0.12)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 14
	phone.add_theme_stylebox_override("panel", sb)
	add_child(phone)

	chat = VBoxContainer.new()
	chat.position = Vector2(12, 78)
	chat.size = Vector2(246, 270)
	chat.add_theme_constant_override("separation", 5)
	chat.clip_contents = true
	phone.add_child(chat)
	_date_pill("HARI INI")

	var ov := Overlay.new()
	ov.painter = _paint_phone
	phone.add_child(ov)

	badge = Panel.new()
	badge.size = Vector2(28, 28)
	badge.position = Vector2(PHONE_SIZE.x - 18, -10)
	badge.pivot_offset = Vector2(14, 14)
	badge.add_theme_stylebox_override("panel", Ui.box(Color(1.0, 0.2, 0.3), Color.WHITE, 14, 2))
	badge.scale = Vector2.ZERO
	var bl := Ui.label(badge, "1", Vector2(0, 2), 16, Color.WHITE, 28)
	bl.custom_minimum_size.x = 28
	phone.add_child(badge)


func _heart(o: CanvasItem, c: Vector2, r: float, col: Color) -> void:
	o.draw_circle(c + Vector2(-r * 0.5, -r * 0.2), r * 0.58, col)
	o.draw_circle(c + Vector2(r * 0.5, -r * 0.2), r * 0.58, col)
	o.draw_colored_polygon(PackedVector2Array([c + Vector2(-r * 1.04, 0.0), c + Vector2(r * 1.04, 0.0), c + Vector2(0, r * 1.1)]), col)


func _paint_phone(o: Overlay) -> void:
	o.draw_style_box(Ui.box(Color(0.07, 0.15, 0.17), Color(0, 0, 0, 0), 24, 0), Rect2(8, 8, PHONE_SIZE.x - 16, 58))
	o.draw_line(Vector2(24, 37), Vector2(32, 30), Color(0.8, 0.9, 0.9), 2.5)
	o.draw_line(Vector2(24, 37), Vector2(32, 44), Color(0.8, 0.9, 0.9), 2.5)
	var c := Vector2(58, 37)
	o.draw_circle(c, 21, Color(0.0, 0.0, 0.0, 0.5))
	o.draw_circle(c, 19, Color(0.55, 0.3, 0.5))
	BoyFace.draw_portrait(o, c, 19.0, GF_TEX, Color(1, 1, 1).lerp(Color(0.6, 0.6, 0.75), clampf(face_g, 0.0, 1.0)))
	Ui.text(o, Vector2(86, 34), "Sayang", 17, Color.WHITE, 0)
	_heart(o, Vector2(86 + Ui.text_width("Sayang", 17) + 12, 28), 6.5 + sin(t * 5.0) * 0.6, Color(1.0, 0.25, 0.45))
	Ui.text(o, Vector2(86, 53), sub_text, 11, GREEN if sub_text == "online" or sub_text == "menaip..." else Color(0.55, 0.65, 0.65), 0)
	o.draw_style_box(Ui.box(Color(0.12, 0.17, 0.2), Color(0, 0, 0, 0), 14, 0), Rect2(14, 356, 200, 28))
	Ui.text(o, Vector2(28, 375), "Mesej", 13, Color(0.45, 0.52, 0.55), 0)
	o.draw_circle(Vector2(240, 370), 14, Color(0.0, 0.5, 0.4))
	o.draw_colored_polygon(PackedVector2Array([Vector2(234, 363), Vector2(247, 370), Vector2(234, 377)]), Color.WHITE)


func _date_pill(text: String) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	var pc := PanelContainer.new()
	var sb := Ui.box(Color(0.12, 0.17, 0.2), Color(0, 0, 0, 0), 8, 0)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	pc.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_color", Color(0.6, 0.7, 0.7))
	pc.add_child(l)
	row.add_child(pc)
	chat.add_child(row)


func _bubble_box(mine: bool) -> StyleBoxFlat:
	var sb := Ui.box(Color(0.0, 0.36, 0.3) if mine else Color(0.125, 0.172, 0.2), Color(0, 0, 0, 0), 11, 0)
	sb.content_margin_left = 10
	sb.content_margin_right = 9
	sb.content_margin_top = 4
	sb.content_margin_bottom = 3
	return sb


func _bubble(text: String, mine: bool, stamp: String) -> void:
	text = Loc.t(text)
	_clear_typing()
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END if mine else BoxContainer.ALIGNMENT_BEGIN
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _bubble_box(mine))
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", -2)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 14)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = minf(200.0, 8.0 * text.length() + 6.0)
	vb.add_child(l)
	var tl := Label.new()
	tl.text = stamp
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tl.add_theme_font_size_override("font_size", 9)
	tl.add_theme_color_override("font_color", Color(0.6, 0.72, 0.72))
	vb.add_child(tl)
	pc.add_child(vb)
	row.add_child(pc)
	row.modulate.a = 0.0
	pc.pivot_offset = Vector2(0 if not mine else 100, 20)
	pc.scale = Vector2(0.85, 0.85)
	chat.add_child(row)
	var tw := create_tween().set_parallel()
	tw.tween_property(row, "modulate:a", 1.0, 0.25)
	tw.tween_property(pc, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_typing() -> void:
	_clear_typing()
	typing_row = HBoxContainer.new()
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _bubble_box(false))
	typing_dots = Control.new()
	typing_dots.custom_minimum_size = Vector2(38, 16)
	typing_dots.draw.connect(_draw_dots)
	pc.add_child(typing_dots)
	typing_row.add_child(pc)
	chat.add_child(typing_row)


func _clear_typing() -> void:
	if typing_row != null and is_instance_valid(typing_row):
		typing_row.queue_free()
	typing_row = null
	typing_dots = null


func _draw_dots() -> void:
	if typing_dots == null:
		return
	for i in 3:
		var k := 0.5 + 0.5 * sin(t * 7.0 - i * 0.9)
		typing_dots.draw_circle(Vector2(9 + i * 10, 8 - k * 3.0), 3.0, Color(0.7, 0.8, 0.8, 0.5 + 0.5 * k))


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		skipped = true


func _process(delta: float) -> void:
	t += delta
	for d in drops:
		d.position.y += 380.0 * delta
		d.position.x -= 30.0 * delta
		if d.position.y > 248.0:
			d.position = Vector2(randf() * 255.0, -16.0)
	glow.position.y = phone.position.y + PHONE_SIZE.y / 2.0 - 280.0
	glow.modulate.a = (0.7 + 0.3 * sin(t * 2.5)) if phone.position.y < 500.0 else 0.0
	if typing_dots != null and is_instance_valid(typing_dots):
		typing_dots.queue_redraw()


func hold(sec: float) -> void:
	var el := 0.0
	while el < sec and not skipped:
		await get_tree().process_frame
		el += get_process_delta_time()


func say(text: String, dur: float) -> void:
	caption.text = text
	create_tween().tween_property(cap_panel, "modulate:a", 1.0, 0.6)
	await hold(0.6 + dur)
	create_tween().tween_property(cap_panel, "modulate:a", 0.0, 0.5)
	await hold(0.6)


func _run() -> void:
	create_tween().tween_property(room, "modulate", DIM, 3.0)
	var zoom := create_tween()
	zoom.tween_property(room, "scale", Vector2(1.35, 1.35), 45.0).set_trans(Tween.TRANS_SINE)
	await hold(0.6)
	await say("Malam. Hujan tak berhenti.", 2.4)
	await say("Dah tiga hari dia tak mandi.", 2.4)
	await say("Telefonnya bergetar...", 1.4)
	await _phone_scene()
	await say("Tiada balasan.", 2.2)
	await say("Dia depresi. Dia jadi makin kepam.", 3.0)
	create_tween().tween_property(room, "modulate", Color.BLACK, 2.0)
	await hold(2.4)
	await say("\"Aku akan buktikan aku tak kepam.\"", 2.8)
	_go()


func _notify_pop() -> void:
	Sfx.play("notify")
	var pop := create_tween()
	pop.tween_property(badge, "scale", Vector2(1.35, 1.35), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop.tween_property(badge, "scale", Vector2.ONE, 0.12)
	var shake := create_tween()
	for x in [PHONE_X + 7.0, PHONE_X - 7.0, PHONE_X + 6.0, PHONE_X - 6.0, PHONE_X + 3.0, PHONE_X]:
		shake.tween_property(phone, "position:x", x, 0.045)


func _phone_scene() -> void:
	create_tween().tween_property(room, "modulate", Color(0.3, 0.3, 0.4), 1.0)
	Sfx.play("whoosh", -4.0)
	create_tween().tween_property(phone, "position:y", PHONE_Y, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await hold(1.6)
	sub_text = "online"
	_notify_pop()
	await hold(1.2)
	sub_text = "menaip..."
	_show_typing()
	await hold(2.2)
	create_tween().tween_property(badge, "scale", Vector2.ZERO, 0.2)
	sub_text = "online"
	Sfx.play("notify", -4.0)
	_bubble("You terlalu kepam untuk I,", false, "11:46")
	await hold(0.9)
	sub_text = "menaip..."
	_show_typing()
	await hold(1.1)
	sub_text = "online"
	Sfx.play("notify", -4.0)
	_bubble("kita break.", false, "11:46")
	face_g = 0.5
	await hold(0.9)
	_show_typing()
	await hold(0.9)
	Sfx.play("notify", -2.0)
	_bubble("Bye.", false, "11:47")
	face_g = 0.75
	await hold(1.2)
	sub_text = "terakhir dilihat sebentar tadi"
	await hold(2.4)
	Sfx.play("click")
	_bubble("Sayang?", true, "11:52")
	await hold(1.6)
	Sfx.play("click")
	_bubble("tunggu dulu...", true, "11:52")
	await hold(3.0)
	create_tween().tween_property(phone, "position:y", 570.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	create_tween().tween_property(room, "modulate", Color(0.55, 0.55, 0.65), 1.2)
	await hold(1.3)


func _go() -> void:
	Sfx.stop_loop("rain_loop")
	var comic := ComicStrip.new()
	add_child(comic)
	await comic.finished
	GameState.intro_seen = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")
