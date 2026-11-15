class_name DialogueBox
extends Control
# Stardew-style dialogue: big portrait on the right, wooden name tab, parchment box, typewriter text, choices.

signal chosen(index: int)
signal line_done
signal typed

const WOOD := Color(0.55, 0.3, 0.1)
const WOOD_DARK := Color(0.33, 0.16, 0.05)
const PARCH := Color(0.99, 0.85, 0.56)
const INK := Color(0.32, 0.15, 0.04)
const BOX := Rect2(20, 324, 920, 160)

var portrait := TextureRect.new()
var name_l := Label.new()
var text_l := Label.new()
var arrow := Label.new()
var choice_btns: Array[Button] = []
var typing := false
var shown := 0.0
var full_text := ""
var t := 0.0
var choosing := false
var pending_choice := false


func _ready() -> void:
	size = Vector2(960, 540)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.0, 0.08, 0.6)
	dim.size = Vector2(960, 540)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)

	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.size = Vector2(300, 300)
	portrait.position = Vector2(620, 14)
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(portrait)

	var tab := _frame(Rect2(60, BOX.position.y - 38, 190, 42))
	name_l.position = Vector2(14, 5)
	name_l.size = Vector2(162, 30)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.add_theme_font_size_override("font_size", 20)
	name_l.add_theme_color_override("font_color", INK)
	tab.add_child(name_l)

	var box := _frame(BOX)
	text_l.position = Vector2(26, 18)
	text_l.size = Vector2(868, 126)
	text_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_l.add_theme_font_size_override("font_size", 24)
	text_l.add_theme_color_override("font_color", INK)
	box.add_child(text_l)

	arrow.text = "v"
	arrow.add_theme_font_size_override("font_size", 22)
	arrow.add_theme_color_override("font_color", WOOD_DARK)
	arrow.position = Vector2(BOX.end.x - 52, BOX.end.y - 40)
	arrow.visible = false
	add_child(arrow)

	for i in 4:
		var b := Button.new()
		b.visible = false
		b.add_theme_font_size_override("font_size", 18)
		b.add_theme_color_override("font_color", INK)
		b.add_theme_color_override("font_hover_color", Color(0.7, 0.1, 0.05))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.93, 0.74, 0.42)
		sb.set_corner_radius_all(4)
		sb.set_border_width_all(3)
		sb.border_color = WOOD
		sb.content_margin_left = 14
		sb.content_margin_right = 14
		var sb_h: StyleBoxFlat = sb.duplicate()
		sb_h.bg_color = Color(1.0, 0.92, 0.65)
		for state in ["normal", "pressed", "focus"]:
			b.add_theme_stylebox_override(state, sb)
		b.add_theme_stylebox_override("hover", sb_h)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.pressed.connect(_pick.bind(i))
		add_child(b)
		choice_btns.append(b)


func _frame(r: Rect2) -> Panel:
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	var sb := StyleBoxFlat.new()
	sb.bg_color = PARCH
	sb.set_border_width_all(8)
	sb.border_color = WOOD
	sb.set_corner_radius_all(6)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 6
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	return p


func open(who: String, tex: Texture2D) -> void:
	name_l.text = who
	portrait.texture = tex
	visible = true
	choosing = false
	_hide_choices()


func close() -> void:
	visible = false


func _start_text(text: String) -> void:
	_hide_choices()
	full_text = text
	text_l.text = text
	text_l.visible_characters = 0
	shown = 0.0
	typing = true
	arrow.visible = false


func say(text: String) -> void:
	pending_choice = false
	_start_text(text)
	await line_done


func ask(text: String, options: Array) -> int:
	pending_choice = true
	_start_text(text)
	await typed
	for i in options.size():
		var b := choice_btns[i]
		b.text = "%s.  %s" % [char(65 + i), options[i]]
		b.size = Vector2(432, 38)
		b.position = Vector2(BOX.position.x + 24 + (i % 2) * 440, BOX.position.y + 64 + (i / 2) * 46)
		b.visible = true
	text_l.size.y = 56
	text_l.add_theme_font_size_override("font_size", 20)
	choosing = true
	var idx: int = await chosen
	text_l.add_theme_font_size_override("font_size", 24)
	text_l.size.y = 126
	choosing = false
	pending_choice = false
	_hide_choices()
	return idx


func _hide_choices() -> void:
	for b in choice_btns:
		b.visible = false


func _pick(i: int) -> void:
	Sfx.play("click")
	chosen.emit(i)


func _finish_typing() -> void:
	typing = false
	text_l.visible_characters = -1
	if pending_choice:
		typed.emit()
	else:
		arrow.visible = true


func _advance() -> bool:
	if typing:
		_finish_typing()
		return true
	if arrow.visible:
		arrow.visible = false
		line_done.emit()
		return true
	return false


func _input(event: InputEvent) -> void:
	if not visible:
		return
	if choosing:
		if event is InputEventKey and event.pressed and not event.echo:
			var k: int = event.keycode - KEY_A
			if k < 0 or k > 3:
				k = event.keycode - KEY_1
			if k >= 0 and k < 4 and choice_btns[k].visible:
				_pick(k)
				get_viewport().set_input_as_handled()
		return
	var press := false
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_E):
		press = true
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		press = true
	if press and _advance():
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	t += delta
	if typing:
		var before := int(shown)
		shown += delta * 42.0
		text_l.visible_characters = int(shown)
		if int(shown) > before and int(shown) % 2 == 0:
			Sfx.play("blip", -12.0, randf_range(0.95, 1.1))
		if int(shown) >= full_text.length():
			_finish_typing()
	if arrow.visible:
		arrow.position.y = BOX.end.y - 40 + sin(t * 6.0) * 4.0
