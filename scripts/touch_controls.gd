extends CanvasLayer
# On-screen joystick and buttons for touch devices. Injects real key / mouse events so the game code needs no changes.

var STICK_C := Vector2(105, 430)
var STICK_R := 62.0
var STICK_ZONE := Rect2(0, 250, 330, 290)
const DEAD := 0.28
var BUTTONS := [
	{"id": "space", "key": KEY_SPACE, "label": "SPACE", "c": Vector2(902, 456), "r": 36.0, "fs": 12},
	{"id": "enter", "key": KEY_ENTER, "label": "ENTER", "c": Vector2(826, 488), "r": 27.0, "fs": 10},
	{"id": "e", "key": KEY_E, "label": "E", "c": Vector2(758, 488), "r": 27.0, "fs": 17},
	{"id": "b", "key": KEY_B, "label": "B", "c": Vector2(692, 488), "r": 27.0, "fs": 17},
	{"id": "esc", "key": KEY_ESCAPE, "label": "", "c": Vector2(936, 26), "r": 15.0, "fs": 10},
]

var shown := false
var _base_buttons: Array = []
var forced := false
var pad: Overlay
var touches := {}
var held := {}
var stick_vec := Vector2.ZERO
var stick_touch := -1
var mouse_touch := -1
var last_scene: Node


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	forced = "--touch" in OS.get_cmdline_args() or "--touch" in OS.get_cmdline_user_args() or OS.get_environment("ANTI_KEPAM_TOUCH") != ""
	shown = forced or DisplayServer.is_touchscreen_available()
	if not shown and OS.has_feature("web"):
		shown = bool(JavaScriptBridge.eval("(/Android|iPhone|iPad|iPod|Mobile/i.test(navigator.userAgent) || navigator.maxTouchPoints > 0)"))
	var cfg := ConfigFile.new()
	if cfg.load("user://settings.cfg") == OK and cfg.has_section_key("game", "touch_buttons"):
		shown = bool(cfg.get_value("game", "touch_buttons"))
	_base_buttons = BUTTONS.duplicate(true)
	pad = Overlay.new()
	pad.painter = _paint
	pad.visible = shown
	add_child(pad)
	relayout()


func relayout() -> void:
	var k := 1.3 if Save.opt("large_touch") else 1.0
	var flip := Save.opt("left_hand")
	STICK_R = 62.0 * k
	STICK_C = Vector2(855 if flip else 105, 430)
	STICK_ZONE = Rect2(630 if flip else 0, 250, 330, 290)
	for i in BUTTONS.size():
		var b: Dictionary = BUTTONS[i]
		var base: Dictionary = _base_buttons[i]
		var c: Vector2 = base["c"]
		if b["id"] != "esc":
			c = Vector2(960.0 - c.x, c.y) if flip else c
			b["r"] = float(base["r"]) * k
		b["c"] = c
	pad.queue_redraw()


func set_visible_pref(on: bool) -> void:
	shown = on
	pad.visible = on
	_release_all()
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	cfg.set_value("game", "touch_buttons", on)
	cfg.save("user://settings.cfg")


func _process(_delta: float) -> void:
	var cur := get_tree().current_scene
	if cur != last_scene:
		last_scene = cur
		_release_all()


func _release_all() -> void:
	touches.clear()
	stick_touch = -1
	stick_vec = Vector2.ZERO
	if mouse_touch != -1:
		_mouse_button(_last_mouse, false)
		mouse_touch = -1
	for k in held.keys():
		_key(k, false)


var _last_mouse := Vector2.ZERO


func _key(code: int, down: bool) -> void:
	if bool(held.get(code, false)) == down:
		return
	held[code] = down
	var ev := InputEventKey.new()
	ev.keycode = code as Key
	ev.physical_keycode = code as Key
	ev.pressed = down
	Input.parse_input_event(ev)


func _to_window(p: Vector2) -> Vector2:
	return get_viewport().get_final_transform() * p


func _mouse_button(p: Vector2, down: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = down
	ev.position = _to_window(p)
	ev.global_position = ev.position
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	Input.parse_input_event(ev)


func _mouse_move(p: Vector2, rel: Vector2) -> void:
	var ev := InputEventMouseMotion.new()
	ev.position = _to_window(p)
	ev.global_position = ev.position
	ev.relative = rel
	ev.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(ev)


func _hit_button(p: Vector2) -> int:
	for i in BUTTONS.size():
		var b: Dictionary = BUTTONS[i]
		var rad: float = b["r"] + 8.0
		if p.distance_to(b["c"]) <= rad:
			return i
	return -1


func _apply_stick() -> void:
	_key(KEY_LEFT, stick_vec.x < -DEAD)
	_key(KEY_RIGHT, stick_vec.x > DEAD)
	_key(KEY_UP, stick_vec.y < -DEAD)
	_key(KEY_DOWN, stick_vec.y > DEAD)


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			var bi := _hit_button(p) if pad.visible else -1
			if bi >= 0:
				touches[event.index] = BUTTONS[bi]["id"]
				_key(BUTTONS[bi]["key"], true)
			elif pad.visible and STICK_ZONE.has_point(p) and stick_touch == -1:
				stick_touch = event.index
				touches[event.index] = "stick"
				stick_vec = ((p - STICK_C) / STICK_R).limit_length(1.0)
				_apply_stick()
			elif mouse_touch == -1:
				mouse_touch = event.index
				touches[event.index] = "mouse"
				_last_mouse = p
				_mouse_move(p, Vector2.ZERO)
				_mouse_button(p, true)
		else:
			var role: String = touches.get(event.index, "")
			touches.erase(event.index)
			if role == "stick":
				stick_touch = -1
				stick_vec = Vector2.ZERO
				_apply_stick()
			elif role == "mouse":
				mouse_touch = -1
				_mouse_button(p, false)
			else:
				for b in BUTTONS:
					if b["id"] == role:
						_key(b["key"], false)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var p: Vector2 = event.position
		var role: String = touches.get(event.index, "")
		if role == "stick":
			stick_vec = ((p - STICK_C) / STICK_R).limit_length(1.0)
			_apply_stick()
		elif role == "mouse":
			_mouse_move(p, p - _last_mouse)
			_last_mouse = p
		get_viewport().set_input_as_handled()


func _paint(o: Overlay) -> void:
	var base_a := 0.5
	o.draw_circle(STICK_C, STICK_R, Color(Ui.INK.r, Ui.INK.g, Ui.INK.b, 0.4))
	o.draw_arc(STICK_C, STICK_R, 0, TAU, 48, Color(Ui.PINK.r, Ui.PINK.g, Ui.PINK.b, base_a), 3.0, true)
	o.draw_arc(STICK_C, STICK_R * 0.45, 0, TAU, 32, Color(Ui.PINK.r, Ui.PINK.g, Ui.PINK.b, 0.25), 2.0, true)
	var knob := STICK_C + stick_vec * (STICK_R - 18.0)
	o.draw_circle(knob, 26, Color(Ui.INK.r, Ui.INK.g, Ui.INK.b, 0.85))
	o.draw_circle(knob, 22, Color(Ui.PINK.r, Ui.PINK.g, Ui.PINK.b, 0.75 if stick_touch != -1 else 0.5))
	for b in BUTTONS:
		var c: Vector2 = b["c"]
		var r: float = b["r"]
		var down := bool(held.get(b["key"], false))
		var col: Color = Ui.ORANGE if b["id"] == "space" else Ui.PINK
		o.draw_circle(c, r, Color(0.17, 0.05, 0.22, 0.88 if down else 0.55))
		if down:
			o.draw_circle(c, r - 3, Color(col.r, col.g, col.b, 0.45))
		o.draw_arc(c, r, 0, TAU, 40, Color(col.r, col.g, col.b, 0.9), 3.0, true)
		if b["id"] == "esc":
			o.draw_rect(Rect2(c.x - 5, c.y - 6, 3.5, 12), Color.WHITE)
			o.draw_rect(Rect2(c.x + 1.5, c.y - 6, 3.5, 12), Color.WHITE)
		else:
			var s: String = b["label"]
			var fs: int = b["fs"]
			Ui.text(o, c + Vector2(-Ui.text_width(s, fs) / 2.0, fs * 0.36), s, fs, Color.WHITE, 3)
