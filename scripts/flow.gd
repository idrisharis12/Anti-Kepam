extends CanvasLayer
# Scene fades, station intro cards, hold-ENTER-to-skip for cinematics, sound captions, haptics.

const CARDS := {
	"rnr": ["STESEN 1: R&R", "Tekan aksi ikut rentak. Jangan tertidur!"],
	"gas": ["STESEN 2: GAS STATION", "Gosok kotoran dengan mop. Jawab bila orang ketuk."],
	"lrt": ["STESEN 3: LRT", "Swipe kad, jawab soalan hygiene, lepas tu mandi."],
	"mall": ["STESEN 4: MALL", "Lari ke TANDAS. Lipas sedang mengejar kamu!"],
}
const SKIP_HOLD := 1.2

var fade: ColorRect
var card: Control
var card_t := 0.0
var cap: Label
var cap_t := 0.0
var skip_t := 0.0
var skip_ring: Overlay
var last_scene: Node
var skipping := false
const DEFAULT_KEYS := [KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_SPACE, KEY_E, KEY_B]
var custom := {}
var remap_held := {}
var pad_active := false
var pad_keys := {}
var contrast: ColorRect
var gp_ready := false


func _ready() -> void:
	layer = 99
	process_mode = Node.PROCESS_MODE_ALWAYS
	fade = ColorRect.new()
	fade.size = Vector2(960, 540)
	fade.color = Color.BLACK
	fade.modulate.a = 0.0
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fade)
	card = Control.new()
	card.visible = false
	card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(card)
	cap = Label.new()
	cap.position = Vector2(180, 440)
	cap.size = Vector2(600, 30)
	cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap.add_theme_font_size_override("font_size", 16)
	cap.add_theme_color_override("font_color", Color.WHITE)
	cap.add_theme_color_override("font_outline_color", Ui.INK)
	cap.add_theme_constant_override("outline_size", 6)
	cap.visible = false
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(cap)
	var c := ConfigFile.new()
	if c.load(Save.CFG) == OK and c.has_section("keys"):
		for k in c.get_section_keys("keys"):
			custom[int(k)] = int(c.get_value("keys", k))
	contrast = ColorRect.new()
	contrast.size = Vector2(960, 540)
	contrast.color = Color(0, 0, 0, 0)
	contrast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(contrast)
	skip_ring = Overlay.new()
	skip_ring.painter = _paint_skip
	skip_ring.visible = false
	add_child(skip_ring)
	if "--dev" in OS.get_cmdline_args() or "--dev" in OS.get_cmdline_user_args():
		dev_checklist()
	gp_call("loading")


func caption(s: String) -> void:
	if not Save.opt("high_contrast") and not Save.opt("captions"):
		return
	cap.text = "[ %s ]" % Loc.t(s)
	cap.visible = true
	cap_t = 1.6


func buzz(ms := 40) -> void:
	if Touch.shown:
		Input.vibrate_handheld(ms)


func _process(delta: float) -> void:
	var cur := get_tree().current_scene
	if cur != last_scene:
		last_scene = cur
		skipping = false
		skip_t = 0.0
		if not Save.opt("reduce_motion"):
			fade.modulate.a = 1.0
			create_tween().tween_property(fade, "modulate:a", 0.0, 0.35)
		var id := cur.scene_file_path.get_file().get_basename() if cur != null else ""
		if CARDS.has(id):
			_show_card(id)
	if card.visible:
		card_t -= delta
		card.modulate.a = clampf(card_t * 3.0, 0.0, 1.0)
		if card_t <= 0.0 or Input.is_key_pressed(KEY_SPACE) and card_t < 1.6:
			card.visible = false
	if cap.visible:
		cap_t -= delta
		if cap_t <= 0.0:
			cap.visible = false
	_skip_check(delta, cur)
	_pad_axes()
	contrast.color = Color(0, 0, 0, 0.18) if Save.opt("high_contrast") else Color(0, 0, 0, 0)


func _show_card(id: String) -> void:
	for c in card.get_children():
		c.queue_free()
	var p := Ui.panel(card, Rect2(230, 60, 500, 96), Ui.ORANGE)
	p.modulate.a = 0.95
	var h := Ui.label(card, CARDS[id][0], Vector2(230, 68), 28, Ui.ORANGE, 500)
	h.text = Loc.t(CARDS[id][0])
	var s := Ui.label(card, Loc.t(CARDS[id][1]), Vector2(250, 112), 15, Ui.CREAM, 460)
	s.text = Loc.t(CARDS[id][1])
	card.visible = true
	card.modulate.a = 1.0
	card_t = 2.4


func _skip_check(delta: float, cur: Node) -> void:
	var id := cur.scene_file_path.get_file().get_basename() if cur != null else ""
	var skippable := id == "intro" or id == "outro"
	if skippable and not skipping and Input.is_key_pressed(KEY_ENTER) and not get_tree().paused:
		skip_t += delta
	else:
		skip_t = maxf(0.0, skip_t - delta * 3.0)
	skip_ring.visible = skip_t > 0.15
	skip_ring.queue_redraw()
	if skip_t >= SKIP_HOLD and not skipping:
		skipping = true
		skip_t = 0.0
		if id == "intro":
			GameState.intro_seen = true
			get_tree().change_scene_to_file("res://scenes/main.tscn")
		else:
			GameState.reset()
			get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _paint_skip(o: Overlay) -> void:
	var c := Vector2(906, 490)
	o.draw_circle(c, 22, Color(0.05, 0.0, 0.1, 0.8))
	o.draw_arc(c, 18, -PI / 2, -PI / 2 + TAU * clampf(skip_t / SKIP_HOLD, 0.0, 1.0), 32, Ui.ORANGE, 4.0, true)
	Ui.text(o, Vector2(c.x - 70, c.y + 40), Loc.t("Tahan %s = langkau") % prompt("terus"), 11, Color.WHITE, 3)


func key_for(i: int) -> int:
	return custom.get(i, DEFAULT_KEYS[i])


func set_key(i: int, code: int) -> void:
	custom[i] = code
	var c := ConfigFile.new()
	c.load(Save.CFG)
	c.set_value("keys", str(i), code)
	c.save(Save.CFG)


func reset_keys() -> void:
	custom.clear()
	var c := ConfigFile.new()
	c.load(Save.CFG)
	if c.has_section("keys"):
		c.erase_section("keys")
	c.save(Save.CFG)


func _pad_key(code: int, down: bool) -> void:
	if bool(pad_keys.get(code, false)) == down:
		return
	pad_keys[code] = down
	var ev := InputEventKey.new()
	ev.keycode = code as Key
	ev.physical_keycode = code as Key
	ev.pressed = down
	Input.parse_input_event(ev)


func _pad_axes() -> void:
	if Input.get_connected_joypads().is_empty():
		return
	var d := 0
	var x := Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var y := Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	_pad_key(KEY_LEFT, x < -0.4 or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT))
	_pad_key(KEY_RIGHT, x > 0.4 or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT))
	_pad_key(KEY_UP, y < -0.4 or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP))
	_pad_key(KEY_DOWN, y > 0.4 or Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN))
	_pad_key(KEY_SPACE, Input.is_joy_button_pressed(0, JOY_BUTTON_A))
	_pad_key(KEY_E, Input.is_joy_button_pressed(0, JOY_BUTTON_X))
	_pad_key(KEY_B, Input.is_joy_button_pressed(0, JOY_BUTTON_Y))
	_pad_key(KEY_ENTER, Input.is_joy_button_pressed(0, JOY_BUTTON_START))
	if Input.is_joy_button_pressed(0, JOY_BUTTON_B) and not pad_keys.get(KEY_ESCAPE, false):
		_pad_key(KEY_ESCAPE, true)
	elif not Input.is_joy_button_pressed(0, JOY_BUTTON_B):
		_pad_key(KEY_ESCAPE, false)


func prompt(action: String) -> String:
	if pad_active:
		return {"aksi": "A", "jawab": "X", "beli": "Y", "terus": "START"}.get(action, "")
	return {"aksi": "SPACE", "jawab": "E", "beli": "B", "terus": "ENTER"}.get(action, "")


func gp_call(fn: String) -> void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("try{if(window.GamePix&&GamePix.%s){GamePix.%s();}}catch(e){}" % [fn, fn])


func dev_checklist() -> void:
	var missing := []
	var extra := FileAccess.get_file_as_string("res://scripts/i18n.gd")
	var used := {}
	var dir := DirAccess.open("res://scripts")
	for f in dir.get_files():
		if f.ends_with(".gd"):
			var src := FileAccess.get_file_as_string("res://scripts/" + f)
			for m in RegEx.create_from_string('Sfx\\.(?:play|loop)\\("([a-z_]+)"').search_all(src):
				used[m.get_string(1)] = true
	var sfx := DirAccess.open("res://audio/sfx")
	var unused := []
	for f in sfx.get_files():
		if f.ends_with(".wav") and not used.has(f.get_basename()):
			unused.append(f)
	var big := []
	for f in DirAccess.open("res://assets").get_files():
		if f.ends_with(".png") or f.ends_with(".jpg"):
			var sz := FileAccess.open("res://assets/" + f, FileAccess.READ).get_length()
			if sz > 2000000:
				big.append("%s %dKB" % [f, sz / 1024])
	print("[DEV] unused sfx: ", unused)
	print("[DEV] big assets: ", big)
	print("[DEV] i18n entries: ", extra.count('": "'))


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton or (event is InputEventJoypadMotion and absf(event.axis_value) > 0.5):
		pad_active = true
	elif event is InputEventKey or event is InputEventMouseButton:
		pad_active = false
	if not (event is InputEventKey) or custom.is_empty() or event.echo:
		return
	for i in custom:
		if event.keycode == custom[i] and custom[i] != DEFAULT_KEYS[i]:
			var ev := InputEventKey.new()
			ev.keycode = DEFAULT_KEYS[i] as Key
			ev.physical_keycode = DEFAULT_KEYS[i] as Key
			ev.pressed = event.pressed
			Input.parse_input_event(ev)
			get_viewport().set_input_as_handled()
			return
