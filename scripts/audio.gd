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
const CFG := "user://settings.cfg"


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for n in ["Music", "SFX"]:
		AudioServer.add_bus()
		var i := AudioServer.bus_count - 1
		AudioServer.set_bus_name(i, n)
		AudioServer.set_bus_send(i, "Master")
	var cfg := ConfigFile.new()
	if cfg.load(CFG) == OK:
		music_vol = cfg.get_value("audio", "music", music_vol)
		sfx_vol = cfg.get_value("audio", "sfx", sfx_vol)
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


func _save() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music", music_vol)
	cfg.set_value("audio", "sfx", sfx_vol)
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
	panel.position = Vector2(280, 130)
	panel.size = Vector2(400, 280)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.1, 0.02, 0.16, 0.97)
	sb.set_border_width_all(5)
	sb.border_color = Color(1.0, 0.25, 0.55)
	sb.set_corner_radius_all(4)
	panel.add_theme_stylebox_override("panel", sb)
	layer.add_child(panel)
	var t := Label.new()
	t.text = "TETAPAN AUDIO"
	t.position = Vector2(0, 14)
	t.size = Vector2(400, 36)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 26)
	t.add_theme_color_override("font_color", Color(1.0, 0.72, 0.15))
	panel.add_child(t)
	_slider(panel, "Muzik", 70, music_vol, func(v: float) -> void:
		music_vol = v
		_apply()
		_save())
	_slider(panel, "Bunyi", 140, sfx_vol, func(v: float) -> void:
		sfx_vol = v
		_apply()
		_save()
		play("coin", 0.0))
	var hint := Label.new()
	hint.text = "ESC untuk tutup"
	hint.position = Vector2(0, 230)
	hint.size = Vector2(400, 24)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 15)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	panel.add_child(hint)


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
	layer.visible = open
	get_tree().paused = open
	play("click")


func _input(event: InputEvent) -> void:
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
	for p in pool:
		if not p.playing:
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
