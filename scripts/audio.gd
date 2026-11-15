extends Node
# Sound manager. SFX live in res://audio/sfx/<name>.wav, music in res://audio/music/<name>.(ogg|mp3|wav).
# Missing files are skipped silently so the game runs before music is installed.

const MUSIC_EXT := ["ogg", "mp3", "wav"]

var pool: Array[AudioStreamPlayer] = []
var loops := {}
var music := AudioStreamPlayer.new()
var music_name := ""
var music_vol := 0.8
var sfx_vol := 0.8
var layer: CanvasLayer
var open := false
var pages: Array[Control] = []
var opt_btns := {}
var key_btns := {}
var rebinding := -1
var ui_vol := 0.8
var tension_p: AudioStreamPlayer
var foot_t := 0.0
const UI_SFX := ["click", "blip", "whoosh"]
const CAPTIONS := {"skitter": "lipas merayap", "spray": "semburan racun", "knock": "ketukan pintu", "ghost": "bunyi seram", "notify": "mesej masuk", "swipe": "kad di-swipe", "fail": "gagal", "success": "berjaya", "slap": "tamparan"}
const CFG := "user://settings.cfg"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in ["Music", "SFX", "UI"]:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, n)
		AudioServer.set_bus_send(i, "Master")
	var cfg := ConfigFile.new()
	if cfg.load(CFG) == OK:
		music_vol = cfg.get_value("audio", "music", music_vol)
		sfx_vol = cfg.get_value("audio", "sfx", sfx_vol)
		ui_vol = cfg.get_value("audio", "ui", ui_vol)
	_apply()
	for i in 8:
		var p := AudioStreamPlayer.new()
		p.bus = "SFX"
		add_child(p)
		pool.append(p)
	music.bus = "Music"
	add_child(music)
	_build_settings()


func _apply() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_vol, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sfx_vol, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Music"), music_vol <= 0.001)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), sfx_vol <= 0.001)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("UI"), linear_to_db(maxf(ui_vol, 0.0001)))
	AudioServer.set_bus_mute(AudioServer.get_bus_index("UI"), ui_vol <= 0.001)


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.load(CFG)
	cfg.set_value("audio", "music", music_vol)
	cfg.set_value("audio", "sfx", sfx_vol)
	cfg.set_value("audio", "ui", ui_vol)
	cfg.save(CFG)


func _build_settings() -> void:
	layer = CanvasLayer.new()
	layer.layer = 100
	layer.visible = false
	add_child(layer)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.0, 0.07, 0.75)
	dim.size = Vector2(960, 540)
	layer.add_child(dim)
	var panel := Panel.new()
	panel.position = Vector2(200, 50)
	panel.size = Vector2(560, 440)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.02, 0.16, 0.97)
	sb.set_border_width_all(5)
	sb.border_color = Color(1.0, 0.25, 0.55)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)
	var t := Label.new()
	t.text = Loc.t("TETAPAN")
	t.position = Vector2(0, 10)
	t.size = Vector2(560, 36)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 26)
	t.add_theme_color_override("font_color", Color(1.0, 0.72, 0.15))
	panel.add_child(t)
	var names := ["AUDIO", "PILIHAN", "KEKUNCI"]
	for i in 3:
		var pg := Control.new()
		pg.position = Vector2(0, 100)
		pg.size = Vector2(560, 300)
		panel.add_child(pg)
		pages.append(pg)
		var tb := Button.new()
		tb.text = Loc.t(names[i])
		tb.position = Vector2(60 + i * 150, 54)
		tb.size = Vector2(140, 32)
		tb.focus_mode = Control.FOCUS_NONE
		tb.pressed.connect(_show_page.bind(i))
		panel.add_child(tb)
	_slider(pages[0], Loc.t("Muzik"), 0, music_vol, func(v: float) -> void:
		music_vol = v
		_apply()
		_save())
	_slider(pages[0], Loc.t("Bunyi"), 70, sfx_vol, func(v: float) -> void:
		sfx_vol = v
		_apply()
		_save()
		play("coin", 0.0))
	_slider(pages[0], Loc.t("Bunyi UI"), 140, ui_vol, func(v: float) -> void:
		ui_vol = v
		_apply()
		_save()
		play("click"))
	var ll := Label.new()
	ll.text = Loc.t("Bahasa")
	ll.position = Vector2(30, 218)
	ll.add_theme_font_size_override("font_size", 20)
	pages[0].add_child(ll)
	for i in 2:
		var code: String = ["ms", "en"][i]
		var lb := Button.new()
		lb.text = ["MS", "EN"][i]
		lb.position = Vector2(380 + i * 60, 214)
		lb.size = Vector2(54, 32)
		lb.focus_mode = Control.FOCUS_NONE
		lb.pressed.connect(func() -> void:
			Loc.set_lang(code)
			play("click")
			var sc := get_tree().current_scene
			if sc != null and sc.scene_file_path.ends_with("menu.tscn"):
				toggle_settings()
				get_tree().reload_current_scene())
		pages[0].add_child(lb)
	var opts := [["touch", "Butang sentuh"], ["reduce_motion", "Kurangkan gerakan"], ["high_contrast", "Kontras tinggi"], ["large_touch", "Butang sentuh besar"], ["left_hand", "Susunan tangan kiri"], ["captions", "Sari kata bunyi"], ["mute_blur", "Senyap bila tab hilang"]]
	for i in opts.size():
		var key: String = opts[i][0]
		var ol := Label.new()
		ol.text = Loc.t(opts[i][1])
		ol.position = Vector2(30, 6 + i * 40)
		ol.add_theme_font_size_override("font_size", 18)
		pages[1].add_child(ol)
		var ob := Button.new()
		ob.position = Vector2(400, 2 + i * 40)
		ob.size = Vector2(110, 30)
		ob.focus_mode = Control.FOCUS_NONE
		ob.toggle_mode = true
		ob.text = Loc.t("OFF")
		ob.toggled.connect(func(on: bool) -> void:
			ob.text = Loc.t("ON") if on else Loc.t("OFF")
			play("click")
			if key == "touch":
				Touch.set_visible_pref(on)
			else:
				Save.set_opt(key, on)
				if key == "left_hand" or key == "large_touch":
					Touch.relayout())
		pages[1].add_child(ob)
		opt_btns[key] = ob
	var il := Label.new()
	il.text = Loc.t("Klik butang, kemudian tekan kekunci baru")
	il.position = Vector2(30, 0)
	il.add_theme_font_size_override("font_size", 14)
	il.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	pages[2].add_child(il)
	var kn := ["Atas", "Bawah", "Kiri", "Kanan", "Aksi / Mandi", "Jawab pintu", "Beli"]
	for i in kn.size():
		var ka := Label.new()
		ka.text = Loc.t(kn[i])
		ka.position = Vector2(30, 28 + i * 34)
		ka.add_theme_font_size_override("font_size", 17)
		pages[2].add_child(ka)
		var kb := Button.new()
		kb.position = Vector2(380, 26 + i * 34)
		kb.size = Vector2(130, 28)
		kb.focus_mode = Control.FOCUS_NONE
		kb.pressed.connect(func() -> void:
			rebinding = i
			kb.text = "..."
			key_btns[i] = kb)
		pages[2].add_child(kb)
		key_btns[i] = kb
	var rs := Button.new()
	rs.text = Loc.t("Set semula kekunci")
	rs.position = Vector2(30, 268)
	rs.size = Vector2(200, 28)
	rs.focus_mode = Control.FOCUS_NONE
	rs.pressed.connect(func() -> void:
		Flow.reset_keys()
		_refresh_keys())
	pages[2].add_child(rs)
	var hint := Label.new()
	hint.text = Loc.t("ESC untuk tutup")
	hint.position = Vector2(0, 408)
	hint.size = Vector2(560, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	panel.add_child(hint)
	_show_page(0)


func _show_page(i: int) -> void:
	for k in pages.size():
		pages[k].visible = k == i


func _refresh_opts() -> void:
	for k in opt_btns:
		var on: bool = Touch.shown if k == "touch" else Save.opt(k)
		var b: Button = opt_btns[k]
		b.set_pressed_no_signal(on)
		b.text = Loc.t("ON") if on else Loc.t("OFF")


func _refresh_keys() -> void:
	for i in key_btns:
		var b: Button = key_btns[i]
		b.text = OS.get_keycode_string(Flow.key_for(i))


func _slider(parent: Control, text: String, y: float, val: float, cb: Callable) -> void:
	var l := Label.new()
	l.text = text
	l.position = Vector2(30, y)
	l.add_theme_font_size_override("font_size", 20)
	parent.add_child(l)
	var pct := Label.new()
	pct.position = Vector2(320, y)
	pct.size = Vector2(60, 28)
	pct.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	pct.add_theme_font_size_override("font_size", 20)
	pct.text = "%d%%" % int(val * 100)
	parent.add_child(pct)
	var sl := HSlider.new()
	sl.position = Vector2(30, y + 34)
	sl.size = Vector2(340, 24)
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = val
	sl.focus_mode = Control.FOCUS_NONE
	sl.value_changed.connect(func(v: float) -> void:
		pct.text = "%d%%" % int(v * 100)
		cb.call(v))
	parent.add_child(sl)


func toggle_settings() -> void:
	open = not open
	rebinding = -1
	if open:
		_refresh_opts()
		_refresh_keys()
	layer.visible = open
	get_tree().paused = open
	play("click")


func _input(event: InputEvent) -> void:
	if open and rebinding >= 0 and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode != KEY_ESCAPE:
			Flow.set_key(rebinding, event.keycode)
		rebinding = -1
		_refresh_keys()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		toggle_settings()
		get_viewport().set_input_as_handled()


func _find(path: String) -> AudioStream:
	if ResourceLoader.exists(path):
		return load(path)
	return null


func play(sfx: String, vol_db := 0.0, pitch := 1.0) -> void:
	var s := _find("res://audio/sfx/%s.wav" % sfx)
	if s == null:
		return
	if CAPTIONS.has(sfx):
		var fl := get_node_or_null("/root/Flow")
		if fl != null:
			fl.caption(CAPTIONS[sfx])
	for p in pool:
		if not p.playing:
			p.bus = "UI" if sfx in UI_SFX else "SFX"
			p.stream = s
			p.volume_db = vol_db
			p.pitch_scale = pitch
			p.play()
			return


func loop(sfx: String, vol_db := -6.0) -> void:
	if loops.has(sfx):
		return
	var s := _find("res://audio/sfx/%s.wav" % sfx)
	if s == null:
		return
	var p := AudioStreamPlayer.new()
	p.bus = "SFX"
	p.stream = s
	p.volume_db = vol_db
	p.finished.connect(p.play)
	add_child(p)
	p.play()
	loops[sfx] = p


func stop_loop(sfx: String) -> void:
	if loops.has(sfx):
		var p: AudioStreamPlayer = loops[sfx]
		loops.erase(sfx)
		p.finished.disconnect(p.play)
		p.queue_free()


func stop_all_loops() -> void:
	for k in loops.keys():
		stop_loop(k)


func play_music(track: String, vol_db := -8.0) -> void:
	if track == music_name:
		return
	music_name = track
	music.stop()
	for ext in MUSIC_EXT:
		var s := _find("res://audio/music/%s.%s" % [track, ext])
		if s != null:
			if s is AudioStreamOggVorbis or s is AudioStreamMP3:
				s.loop = true
			music.stream = s
			music.volume_db = vol_db
			music.play()
			return


func set_tension(v: float) -> void:
	if tension_p == null:
		var s := _find("res://audio/sfx/pulse_loop.wav")
		if s == null:
			return
		tension_p = AudioStreamPlayer.new()
		tension_p.bus = "SFX"
		tension_p.stream = s
		tension_p.finished.connect(tension_p.play)
		add_child(tension_p)
	v = clampf(v, 0.0, 1.0)
	if v < 0.03:
		if tension_p.playing:
			tension_p.stop()
		return
	tension_p.volume_db = lerpf(-30.0, -4.0, v)
	tension_p.pitch_scale = lerpf(0.9, 1.4, v)
	if not tension_p.playing:
		tension_p.play()


func footstep() -> void:
	play("footstep", -8.0, randf_range(0.85, 1.15))


func stinger() -> void:
	play("stinger", -2.0)


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and Save.opt("mute_blur"):
		AudioServer.set_bus_mute(0, true)
	elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
		AudioServer.set_bus_mute(0, false)
