extends Node2D
# Start menu: GTA-style key art, big ANTI-KEPAM logo, Mula / Cara Main / Keluar.

const PINK := Color(1.0, 0.25, 0.55)
const ORANGE := Color(1.0, 0.72, 0.15)
const HOW_TO := "[color=#ff4090][b]MATLAMAT[/b][/color]\nBoy kena mandi di [color=#ffb826]4 tempat[/color] (R&R, Gas Station, LRT, Mall), lepas tu terjun ke [color=#ffb826]Golden Lake[/color] sebelum masa GF habis.\n\n[color=#ff4090][b]KAWALAN[/b][/color]\n[color=#ffb826]WASD / Anak panah[/color]  jalan        [color=#ffb826]SPACE[/color]  mandi / aksi\n[color=#ffb826]E[/color]  jawab ketukan        [color=#ffb826]B[/color]  beli sabun & tisu        [color=#ffb826]Mouse[/color]  gosok, seret, klik\n\n[color=#ff4090][b]KALAH BILA[/b][/color]\nKepam merebak [color=#ffb826]satu negeri[/color], jadi viral di [color=#ffb826]Berita Kepam 26[/color], atau GF kahwin lelaki lain."

var lake: TextureRect
var fx: Overlay
var hover_i := -1
var hover_k := [0.0, 0.0, 0.0, 0.0, 0.0]
var glow: ColorRect
var logo_a: Label
var logo_b: Label
var tag: Label
var buttons: Array[Button] = []
var ids: Array[String] = []
var quit_hold := 0.0
var panel: Panel
var t := 0.0
var busy := false


func _ready() -> void:
	Sfx.stop_all_loops()
	Sfx.play_music("menu")

	var bg_tex := AtlasTexture.new()
	bg_tex.atlas = load("res://assets/menu_art.png")
	bg_tex.region = Rect2(0, 396, 1024, 576)
	lake = TextureRect.new()
	lake.texture = bg_tex
	lake.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	lake.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lake.stretch_mode = TextureRect.STRETCH_SCALE
	lake.position = Vector2(-20, -11)
	lake.size = Vector2(1000, 562)
	lake.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lake)

	glow = ColorRect.new()
	glow.size = Vector2(960, 540)
	glow.color = Color(1.0, 0.55, 0.2, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)

	fx = Overlay.new()
	fx.painter = _paint_fx
	add_child(fx)

	logo_a = _logo("ANTI", Vector2(420, 50), 40, ORANGE)
	logo_b = _logo("KEPAM", Vector2(420, 100), 56, PINK)
	tag = _label("Mandi dulu, baru boleh cinta.", Vector2(420, 144), 17, Color(1, 0.93, 0.8))
	tag.add_theme_color_override("font_outline_color", Color(0.2, 0.0, 0.15))
	tag.add_theme_constant_override("outline_size", 8)

	var labels := ["MULA", "CARA MAIN", "AUDIO", "KELUAR"]
	if Save.has_save:
		labels.push_front("LANJUT")
	var y0 := 222 if Save.has_save else 250
	for i in labels.size():
		var b := _button(Loc.t(labels[i]), Vector2(670, y0 + i * 56))
		ids.append(labels[i])
		b.pressed.connect(_on_button.bind(i))
		buttons.append(b)
	if Save.last_loss != "" and GameState.LOSE_TEXT.has(Save.last_loss):
		var ll := _label(Loc.t("Kali lepas:") + " " + Loc.t(GameState.LOSE_TEXT[Save.last_loss]), Vector2(300, 190), 13, Color(1.0, 0.6, 0.65))
		ll.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ll.custom_minimum_size = Vector2(380, 0)
		ll.size = Vector2(380, 44)
		ll.position = Vector2(230, 168)
		ll.pivot_offset = Vector2.ZERO
		ll.add_theme_color_override("font_outline_color", Color(0.2, 0.0, 0.15))
		ll.add_theme_constant_override("outline_size", 6)

	_label("v0.1  -  Game Jam 2026", Vector2(480, 512), 14, Color(1, 1, 1, 0.6))
	_lang_buttons()
	if not Save.lang_chosen():
		_lang_picker()

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
	txt.text = Loc.t(HOW_TO)
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
	b.text = "      " + text
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


func _lang_buttons() -> void:
	for i in 2:
		var code: String = ["ms", "en"][i]
		var b := Button.new()
		b.text = ["MS", "EN"][i]
		b.position = Vector2(836 + i * 56, 16)
		b.size = Vector2(50, 30)
		b.focus_mode = Control.FOCUS_NONE
		b.add_theme_font_size_override("font_size", 17)
		var on: bool = Loc.lang == code
		b.add_theme_color_override("font_color", Color(0.15, 0.0, 0.15) if on else Color(1, 0.95, 0.85))
		b.add_theme_color_override("font_hover_color", Color(0.15, 0.0, 0.15))
		var n := Ui.box(ORANGE if on else Color(0.12, 0.02, 0.2, 0.85), PINK if on else Color(0.05, 0.0, 0.08), 6, 3)
		var h := Ui.box(ORANGE, PINK, 6, 3)
		for st in ["normal", "focus"]:
			b.add_theme_stylebox_override(st, n)
		b.add_theme_stylebox_override("hover", h)
		b.add_theme_stylebox_override("pressed", h)
		b.pressed.connect(func() -> void:
			if Loc.lang == code:
				return
			Sfx.play("click")
			Loc.set_lang(code)
			get_tree().reload_current_scene())
		add_child(b)


func _lang_picker() -> void:
	var layer := Control.new()
	layer.size = Vector2(960, 540)
	add_child(layer)
	var dim := ColorRect.new()
	dim.size = Vector2(960, 540)
	dim.color = Color(0.03, 0, 0.07, 0.88)
	layer.add_child(dim)
	var h := Ui.label(layer, "PILIH BAHASA  /  CHOOSE LANGUAGE", Vector2(130, 170), 26, ORANGE, 700)
	h.text = "PILIH BAHASA  /  CHOOSE LANGUAGE"
	for i in 2:
		var code: String = ["ms", "en"][i]
		var b := Button.new()
		b.text = ["Bahasa Melayu", "English"][i]
		b.position = Vector2(260 + i * 230, 250)
		b.size = Vector2(210, 70)
		b.add_theme_font_size_override("font_size", 22)
		b.pressed.connect(func() -> void:
			Loc.set_lang(code)
			Save.mark_lang_chosen()
			Sfx.play("click")
			get_tree().reload_current_scene())
		layer.add_child(b)


func _hover(b: Button) -> void:
	if busy:
		return
	Sfx.play("blip", -6.0, 1.2)
	hover_i = buttons.find(b)
	create_tween().tween_property(b, "scale", Vector2(1.08, 1.08), 0.1)


func _unhover(b: Button) -> void:
	if hover_i == buttons.find(b):
		hover_i = -1
	create_tween().tween_property(b, "scale", Vector2.ONE, 0.1)


func _on_button(i: int) -> void:
	if busy:
		return
	Sfx.play("click")
	match ids[i]:
		"LANJUT":
			Save.load_progress()
			_start()
		"MULA":
			GameState.reset()
			_start()
		"CARA MAIN":
			panel.visible = true
		"AUDIO":
			Sfx.toggle_settings()
		"KELUAR":
			if quit_hold <= 0.0:
				quit_hold = 2.0
				buttons[i].text = "      " + Loc.t("Tekan lagi untuk keluar")
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
	var target := "res://scenes/main.tscn" if GameState.intro_seen and GameState.step > 0 else "res://scenes/intro.tscn"
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
	if quit_hold > 0.0:
		quit_hold -= delta
		if quit_hold <= 0.0 and ids.size() > 0:
			buttons[ids.find("KELUAR")].text = "      " + Loc.t("KELUAR")
	if not Save.opt("reduce_motion"):
		lake.position = Vector2(-20 + sin(t * 0.3) * 9.0, -11 + sin(t * 0.4) * 3.0)
	for i in buttons.size():
		hover_k[i] = lerpf(hover_k[i], 1.0 if hover_i == i else 0.0, minf(1.0, delta * 12.0))
	glow.color.a = 0.07 + 0.05 * sin(t * 1.3)
	logo_b.rotation = sin(t * 1.1) * 0.006
	if not Save.opt("reduce_motion"):
		logo_a.position.y = 50 - 40 * 0.8 + sin(t * 1.6) * 2.0


func _paint_fx(o: Overlay) -> void:
	for i in 14:
		var ph := fmod(t * (0.05 + (i % 4) * 0.015) + i * 0.137, 1.0)
		var x := fmod(i * 83.0 + sin(t * 0.5 + i) * 30.0 + 960.0, 960.0)
		var y := 540.0 - ph * 300.0
		var r := 40.0 + (i % 5) * 16.0 + ph * 30.0
		o.draw_circle(Vector2(x, y), r, Color(0.45, 0.85, 0.2, 0.09 * (1.0 - ph)))
	var vig := 150.0
	for i in 8:
		var k := float(i) / 8.0
		var a := 0.55 * (1.0 - k) * (1.0 - k)
		var w := vig * (1.0 / 8.0)
		o.draw_rect(Rect2(0, i * w, 960, w), Color(0.05, 0, 0.1, a * 0.7))
		o.draw_rect(Rect2(0, 540 - (i + 1) * w, 960, w), Color(0.05, 0, 0.1, a))
		o.draw_rect(Rect2(i * w, 0, w, 540), Color(0.05, 0, 0.1, a * 0.8))
		o.draw_rect(Rect2(960 - (i + 1) * w, 0, w, 540), Color(0.05, 0, 0.1, a * 0.8))
	for i in buttons.size():
		var b := buttons[i]
		var c := Vector2(b.position.x + 30.0 + hover_k[i] * 6.0, b.position.y + 25.0 * b.scale.y)
		var col := Color(0.15, 0, 0.15) if hover_k[i] > 0.5 else ORANGE
		col.a = b.modulate.a
		if hover_k[i] > 0.02:
			o.draw_rect(Rect2(b.position.x - 6, b.position.y - 4, 262, 58), Color(1.0, 0.5, 0.2, 0.12 * hover_k[i] * b.modulate.a))
		match ids[i]:
			"LANJUT", "MULA":
				o.draw_colored_polygon(PackedVector2Array([c + Vector2(-7, -9), c + Vector2(9, 0), c + Vector2(-7, 9)]), col)
			"CARA MAIN":
				o.draw_arc(c + Vector2(0, -3), 7, PI, TAU + 1.2, 14, col, 3.0)
				o.draw_circle(c + Vector2(0, 10), 2.2, col)
			"AUDIO":
				o.draw_rect(Rect2(c.x - 9, c.y - 4, 6, 8), col)
				o.draw_colored_polygon(PackedVector2Array([c + Vector2(-3, -4), c + Vector2(4, -10), c + Vector2(4, 10), c + Vector2(-3, 4)]), col)
				o.draw_arc(c + Vector2(5, 0), 6, -0.9, 0.9, 8, col, 2.0)
			"KELUAR":
				o.draw_rect(Rect2(c.x - 7, c.y - 10, 12, 20), col, false, 2.5)
				o.draw_line(c + Vector2(0, 0), c + Vector2(11, 0), col, 2.5)
				o.draw_line(c + Vector2(11, 0), c + Vector2(7, -4), col, 2.5)
				o.draw_line(c + Vector2(11, 0), c + Vector2(7, 4), col, 2.5)
