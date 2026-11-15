extends Node2D
# Start menu: GTA-style key art, big ANTI-KEPAM logo, Mula / Cara Main / Keluar.

const PINK := Color(1.0, 0.25, 0.55)
const ORANGE := Color(1.0, 0.72, 0.15)
const HOW_TO := "[color=#ff4090][b]MATLAMAT[/b][/color]\nBoy kena mandi di [color=#ffb826]4 tempat[/color] (R&R, Gas Station, LRT, Mall), lepas tu terjun ke [color=#ffb826]Golden Lake[/color] sebelum masa GF habis.\n\n[color=#ff4090][b]KAWALAN[/b][/color]\n[color=#ffb826]WASD / Anak panah[/color]  jalan        [color=#ffb826]SPACE[/color]  mandi / aksi\n[color=#ffb826]E[/color]  jawab ketukan        [color=#ffb826]B[/color]  beli sabun & tisu        [color=#ffb826]Mouse[/color]  gosok, seret, klik\n\n[color=#ff4090][b]KALAH BILA[/b][/color]\nKepam merebak [color=#ffb826]satu negeri[/color], jadi viral di [color=#ffb826]Berita Kepam 26[/color], atau GF kahwin lelaki lain."

var art: Sprite2D
var glow: ColorRect
var logo_a: Label
var logo_b: Label
var tag: Label
var buttons: Array[Button] = []
var panel: Panel
var t := 0.0
var busy := false


func _ready() -> void:
	Sfx.stop_all_loops()
	Sfx.play_music("menu")

	art = Sprite2D.new()
	art.texture = load("res://assets/menu_bg.png")
	art.position = Vector2(480, 135)
	art.scale = Vector2(960.0 / 1024.0, 960.0 / 1024.0) * 1.08
	add_child(art)

	glow = ColorRect.new()
	glow.size = Vector2(960, 540)
	glow.color = Color(1.0, 0.55, 0.2, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	var shade := ColorRect.new()
	shade.size = Vector2(960, 540)
	shade.color = Color(0.1, 0.0, 0.15, 0.0)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(shade)
	var grad := Gradient.new()
	grad.set_color(0, Color(0.05, 0.0, 0.1, 0.0))
	grad.set_color(1, Color(0.05, 0.0, 0.1, 0.75))
	var gt := GradientTexture2D.new()
	gt.gradient = grad
	gt.fill_from = Vector2(0.5, 0.45)
	gt.fill_to = Vector2(0.5, 1.0)
	gt.width = 64
	gt.height = 64
	var fade := TextureRect.new()
	fade.texture = gt
	fade.size = Vector2(960, 540)
	fade.stretch_mode = TextureRect.STRETCH_SCALE
	fade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)

	logo_a = _logo("ANTI", Vector2(480, 78), 96, ORANGE)
	logo_b = _logo("KEPAM", Vector2(480, 168), 124, PINK)
	tag = _label("Mandi dulu, baru boleh cinta.", Vector2(480, 252), 22, Color(1, 0.93, 0.8))
	tag.add_theme_color_override("font_outline_color", Color(0.2, 0.0, 0.15))
	tag.add_theme_constant_override("outline_size", 6)

	var labels := ["MULA", "CARA MAIN", "AUDIO", "KELUAR"]
	for i in labels.size():
		var b := _button(labels[i], Vector2(670, 270 + i * 58))
		b.pressed.connect(_on_button.bind(i))
		buttons.append(b)

	_label("v0.1  -  Game Jam 2026", Vector2(480, 512), 14, Color(1, 1, 1, 0.6))

	panel = Panel.new()
	panel.position = Vector2(110, 60)
	panel.size = Vector2(740, 420)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.09, 0.015, 0.15, 0.97)
	sb.set_border_width_all(5)
	sb.border_color = PINK
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.6)
	sb.shadow_size = 12
	panel.add_theme_stylebox_override("panel", sb)
	panel.visible = false
	add_child(panel)
	var head := Label.new()
	head.text = "CARA MAIN"
	head.position = Vector2(0, 14)
	head.size = Vector2(740, 44)
	head.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	head.add_theme_font_size_override("font_size", 34)
	head.add_theme_color_override("font_color", ORANGE)
	head.add_theme_color_override("font_outline_color", Color(0.2, 0.0, 0.15))
	head.add_theme_constant_override("outline_size", 8)
	panel.add_child(head)
	var rule := ColorRect.new()
	rule.color = PINK
	rule.position = Vector2(40, 66)
	rule.size = Vector2(660, 3)
	panel.add_child(rule)
	var txt := RichTextLabel.new()
	txt.bbcode_enabled = true
	txt.scroll_active = false
	txt.position = Vector2(44, 80)
	txt.size = Vector2(652, 290)
	txt.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for f in ["normal_font_size", "bold_font_size"]:
		txt.add_theme_font_size_override(f, 18)
	txt.add_theme_color_override("default_color", Color(1, 0.95, 0.85))
	txt.text = HOW_TO
	panel.add_child(txt)
	var close := Label.new()
	close.text = "klik atau tekan ESC untuk tutup"
	close.position = Vector2(0, 382)
	close.size = Vector2(740, 24)
	close.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	close.add_theme_font_size_override("font_size", 15)
	close.add_theme_color_override("font_color", ORANGE)
	panel.add_child(close)

	var cover := ColorRect.new()
	cover.name = "cover"
	cover.size = Vector2(960, 540)
	cover.color = Color.BLACK
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cover)
	create_tween().tween_property(cover, "modulate:a", 0.0, 1.2)

	for i in [logo_a, logo_b]:
		i.modulate.a = 0.0
		i.scale = Vector2(1.25, 1.25)
	tag.modulate.a = 0.0
	for b in buttons:
		b.modulate.a = 0.0
		b.position.x += 40
	var tw := create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(Sfx.play.bind("whoosh", -6.0))
	tw.tween_property(logo_a, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(logo_a, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(logo_b, "modulate:a", 1.0, 0.4)
	tw.parallel().tween_property(logo_b, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(tag, "modulate:a", 1.0, 0.6)
	for b in buttons:
		tw.tween_property(b, "modulate:a", 1.0, 0.25)
		tw.parallel().tween_property(b, "position:x", b.position.x - 40, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


func _label(text: String, center: Vector2, size: int, col: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.size = Vector2(900, size * 1.6)
	l.position = center - Vector2(450, size * 0.8)
	l.pivot_offset = l.size / 2
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(l)
	return l


func _logo(text: String, center: Vector2, size: int, col: Color) -> Label:
	var l := _label(text, center, size, col)
	l.add_theme_color_override("font_outline_color", Color(0.12, 0.0, 0.14))
	l.add_theme_constant_override("outline_size", int(size * 0.22))
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	l.add_theme_constant_override("shadow_offset_x", 6)
	l.add_theme_constant_override("shadow_offset_y", 8)
	l.add_theme_constant_override("shadow_outline_size", int(size * 0.22))
	return l


func _button(text: String, pos: Vector2) -> Button:
	var b := Button.new()
	b.text = "  " + text
	b.position = pos
	b.size = Vector2(250, 50)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	b.add_theme_color_override("font_hover_color", Color(0.15, 0.0, 0.15))
	b.add_theme_color_override("font_pressed_color", Color(0.15, 0.0, 0.15))
	var n := StyleBoxFlat.new()
	n.bg_color = Color(0.12, 0.02, 0.2, 0.82)
	n.set_border_width_all(4)
	n.border_color = Color(0.05, 0.0, 0.08)
	n.border_width_left = 10
	n.border_color = Color(0.05, 0.0, 0.08)
	n.set_corner_radius_all(3)
	n.skew = Vector2(-0.18, 0)
	var h: StyleBoxFlat = n.duplicate()
	h.bg_color = ORANGE
	h.border_color = PINK
	for s in ["normal", "focus"]:
		b.add_theme_stylebox_override(s, n)
	b.add_theme_stylebox_override("hover", h)
	b.add_theme_stylebox_override("pressed", h)
	b.mouse_entered.connect(_hover.bind(b))
	b.mouse_exited.connect(_unhover.bind(b))
	b.pivot_offset = Vector2(0, 25)
	add_child(b)
	return b


func _hover(b: Button) -> void:
	if busy:
		return
	Sfx.play("blip", -6.0, 1.2)
	create_tween().tween_property(b, "scale", Vector2(1.08, 1.08), 0.1)


func _unhover(b: Button) -> void:
	create_tween().tween_property(b, "scale", Vector2.ONE, 0.1)


func _on_button(i: int) -> void:
	if busy:
		return
	Sfx.play("click")
	if i == 0:
		_start()
	elif i == 1:
		panel.visible = true
	elif i == 2:
		Sfx.toggle_settings()
	else:
		get_tree().quit()


func _start() -> void:
	busy = true
	Sfx.play("success", -4.0)
	var cover: ColorRect = get_node("cover")
	cover.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(cover, "modulate:a", 1.0, 0.9)
	await tw.finished
	var target := "res://scenes/main.tscn" if GameState.intro_seen else "res://scenes/intro.tscn"
	get_tree().change_scene_to_file(target)


func _input(event: InputEvent) -> void:
	if not panel.visible:
		return
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE):
		panel.visible = false
		Sfx.play("click")
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	t += delta
	art.position = Vector2(480 + sin(t * 0.25) * 14.0, 135 + cos(t * 0.19) * 6.0)
	glow.color.a = 0.07 + 0.05 * sin(t * 1.3)
	logo_b.rotation = sin(t * 1.1) * 0.006
	logo_a.position.y = 78 - 96 * 0.8 + sin(t * 1.6) * 2.0
