extends Node2D
# Cinematic intro: rainy bedroom, WhatsApp breakup on the phone, title card. ENTER skips.

const W := 960.0
const H := 540.0
const DIM := Color(0.85, 0.88, 1.0)

var skipped := false
var started := false
var blink_t := 0.0
var room: TextureRect
var rain_clip: Control
var drops: Array[ColorRect] = []
var phone: Panel
var chat: VBoxContainer
var sub_l: Label
var caption: Label
var title_l: Label
var sub_title: Label
var enter_l: Label


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

	_rect(Vector2.ZERO, Vector2(W, 48), Color.BLACK, self)
	_rect(Vector2(0, H - 48), Vector2(W, 48), Color.BLACK, self)

	_build_phone()

	caption = _text("", Vector2(80, 440), Vector2(800, 40), 24, Color(0.9, 0.9, 1.0))
	caption.modulate.a = 0.0
	var hint := _text("ENTER: langkau", Vector2(760, 506), Vector2(180, 24), 13, Color(0.5, 0.5, 0.6))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	title_l = _text("ANTI-KEPAM 26", Vector2(80, 150), Vector2(800, 90), 68, Color(0.7, 0.85, 0.6))
	sub_title = _text("Mandi di R&R, Gas Station, LRT dan Mall,\nlepas tu terjun ke Golden Lake.\n\nWASD / anak panah untuk bergerak", Vector2(80, 260), Vector2(800, 130), 20, Color(0.8, 0.8, 0.9))
	enter_l = _text("Tekan ENTER untuk mula", Vector2(80, 420), Vector2(800, 30), 22, Color.WHITE)
	for l in [title_l, sub_title, enter_l]:
		l.modulate.a = 0.0

	_run()


func _rect(pos: Vector2, size: Vector2, color: Color, parent: Node) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r


func _text(text: String, pos: Vector2, size: Vector2, font: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", font)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	add_child(l)
	return l


func _build_phone() -> void:
	phone = Panel.new()
	phone.size = Vector2(290, 490)
	phone.position = Vector2(335, 570)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.043, 0.078, 0.102)
	sb.set_corner_radius_all(30)
	sb.set_border_width_all(6)
	sb.border_color = Color(0.1, 0.1, 0.12)
	phone.add_theme_stylebox_override("panel", sb)
	add_child(phone)

	_rect(Vector2(18, 22), Vector2(254, 52), Color(0.12, 0.17, 0.2), phone)
	var face := _rect(Vector2(24, 29), Vector2(38, 38), Color(0.35, 0.4, 0.45), phone)
	var init := Label.new()
	init.text = "S"
	init.position = Vector2(12, 4)
	init.add_theme_font_size_override("font_size", 20)
	face.add_child(init)
	var name_l := Label.new()
	name_l.text = "Sayang"
	name_l.position = Vector2(70, 26)
	name_l.add_theme_font_size_override("font_size", 17)
	phone.add_child(name_l)
	sub_l = Label.new()
	sub_l.position = Vector2(70, 48)
	sub_l.add_theme_font_size_override("font_size", 12)
	sub_l.add_theme_color_override("font_color", Color(0.55, 0.65, 0.65))
	phone.add_child(sub_l)

	chat = VBoxContainer.new()
	chat.position = Vector2(18, 92)
	chat.size = Vector2(254, 370)
	chat.add_theme_constant_override("separation", 8)
	phone.add_child(chat)


func _bubble(text: String, mine: bool) -> void:
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_END if mine else BoxContainer.ALIGNMENT_BEGIN
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.0, 0.36, 0.3) if mine else Color(0.125, 0.172, 0.2)
	sb.set_corner_radius_all(10)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	pc.add_theme_stylebox_override("panel", sb)
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", 16)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = minf(228.0, 9.0 * text.length() + 16.0)
	pc.add_child(l)
	row.add_child(pc)
	row.modulate.a = 0.0
	chat.add_child(row)
	create_tween().tween_property(row, "modulate:a", 1.0, 0.3)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		skipped = true


func _process(delta: float) -> void:
	for d in drops:
		d.position.y += 380.0 * delta
		d.position.x -= 30.0 * delta
		if d.position.y > 248.0:
			d.position = Vector2(randf() * 255.0, -16.0)
	if started:
		blink_t += delta
		enter_l.modulate.a = 0.55 + 0.45 * sin(blink_t * 3.0)


func hold(sec: float) -> void:
	var t := 0.0
	while t < sec and not skipped:
		await get_tree().process_frame
		t += get_process_delta_time()


func say(text: String, dur: float) -> void:
	caption.text = text
	create_tween().tween_property(caption, "modulate:a", 1.0, 0.8)
	await hold(0.8 + dur)
	create_tween().tween_property(caption, "modulate:a", 0.0, 0.6)
	await hold(0.7)


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


func _phone_scene() -> void:
	create_tween().tween_property(room, "modulate", Color(0.3, 0.3, 0.4), 1.0)
	Sfx.play("whoosh", -4.0)
	create_tween().tween_property(phone, "position:y", 25.0, 1.1).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await hold(1.6)
	sub_l.text = "online"
	Sfx.play("notify")
	await hold(1.2)
	var shake := create_tween()
	for x in [341.0, 329.0, 341.0, 329.0, 335.0]:
		shake.tween_property(phone, "position:x", x, 0.05)
	await hold(0.4)
	sub_l.text = "menaip..."
	await hold(2.2)
	sub_l.text = "online"
	Sfx.play("notify", -4.0)
	_bubble("You terlalu kepam untuk I,", false)
	await hold(1.5)
	Sfx.play("notify", -4.0)
	_bubble("kita break.", false)
	await hold(1.4)
	Sfx.play("notify", -2.0)
	_bubble("Bye.", false)
	await hold(1.2)
	sub_l.text = "terakhir dilihat sebentar tadi"
	await hold(2.6)
	Sfx.play("click")
	_bubble("Sayang?", true)
	await hold(1.6)
	Sfx.play("click")
	_bubble("tunggu dulu...", true)
	await hold(3.0)
	create_tween().tween_property(phone, "position:y", 570.0, 1.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	create_tween().tween_property(room, "modulate", Color(0.55, 0.55, 0.65), 1.2)
	await hold(1.3)


func _title() -> void:
	create_tween().tween_property(title_l, "modulate:a", 1.0, 2.0)
	await hold(2.2)
	create_tween().tween_property(sub_title, "modulate:a", 1.0, 1.2)
	await hold(1.6)
	started = true
	while not skipped:
		await get_tree().process_frame


func _go() -> void:
	Sfx.stop_loop("rain_loop")
	GameState.intro_seen = true
	get_tree().change_scene_to_file("res://scenes/main.tscn")
