extends Node2D

const CARD := Vector2(200, 250)
const OPEN_FROM := 1

var hover := -1
var t := 0.0
var msg := ""


func _ready() -> void:
	Sfx.stop_all_loops()
	Sfx.play_music("hub")
	var bg := ColorRect.new()
	bg.color = Color(0.1, 0.03, 0.12)
	bg.size = Vector2(960, 540)
	add_child(bg)
	var head := Ui.label(self, "PILIH STESEN", Vector2(0, 20), 36, Ui.ORANGE, 960)
	head.add_theme_constant_override("outline_size", 9)
	Ui.label(self, "Ulang stesen yang dah siap untuk skor lebih tinggi", Vector2(0, 70), 15, Ui.PINK, 960)
	var o := Overlay.new()
	o.painter = _paint
	add_child(o)


func _rect(i: int) -> Rect2:
	return Rect2(Vector2(30 + i * 230, 130), CARD)


func _unlocked(id: String) -> bool:
	return GameState.STATIONS.find(id) < GameState.step


func _process(delta: float) -> void:
	t += delta
	var m := get_global_mouse_position()
	hover = -1
	for i in GameState.STATIONS.size():
		if _rect(i).has_point(m):
			hover = i
	for o in get_children():
		if o is Overlay:
			o.queue_redraw()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Rect2(30, 470, 160, 40).has_point(event.position):
			_back()
		elif hover >= 0:
			_play(hover)
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			return
		if event.keycode == KEY_BACKSPACE or event.keycode == KEY_Q:
			_back()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_4:
			_play(event.keycode - KEY_1)


func _back() -> void:
	Sfx.play("click")
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _play(i: int) -> void:
	var id: String = GameState.STATIONS[i]
	if not _unlocked(id):
		msg = "Belum dibuka. Habiskan stesen ini dulu."
		Sfx.play("fail", -6.0)
		return
	Sfx.play("click")
	GameState.replay_id = id
	GameState.start_station()
	get_tree().change_scene_to_file("res://scenes/%s.tscn" % id)


func _paint(o: Overlay) -> void:
	for i in GameState.STATIONS.size():
		var id: String = GameState.STATIONS[i]
		var r := _rect(i)
		var open := _unlocked(id)
		var col: Color = Ui.GREEN if open else Color(0.5, 0.35, 0.6)
		if i == hover and open:
			col = Ui.ORANGE
		o.draw_style_box(Ui.box(Color(0.17, 0.05, 0.22), col, 10, 3), r)
		Ui.text(o, r.position + Vector2(14, 40), str(i + 1), 30, col, 5)
		Ui.text(o, r.position + Vector2(14, 90), GameState.NAMES[id], 20, Color.WHITE, 4)
		if open:
			var best: float = GameState.best_scores.get(id, GameState.scores.get(id, 0.0))
			Ui.text(o, r.position + Vector2(14, 130), "Skor terbaik", 13, Ui.CREAM, 3)
			Ui.text(o, r.position + Vector2(14, 170), "%d%%" % int(best * 100.0), 36, Ui.ORANGE, 6)
			var stars := 3 if best >= 0.85 else (2 if best >= 0.65 else 1)
			for k in 3:
				o.draw_circle(r.position + Vector2(30 + k * 28, 210), 9, Ui.ORANGE if k < stars else Color(0.3, 0.2, 0.35))
			Ui.text(o, r.position + Vector2(14, 240), "Klik / tekan %d untuk main" % (i + 1), 11, Ui.WATER, 3)
		else:
			Ui.text(o, r.position + Vector2(14, 140), "Terkunci", 18, Color(0.7, 0.6, 0.75), 3)
	o.draw_style_box(Ui.box(Color(0.14, 0.04, 0.2), Ui.WATER, 8, 2), Rect2(30, 470, 160, 40))
	Ui.text(o, Vector2(48, 496), "< Balik hub", 17, Color.WHITE, 3)
	if msg != "":
		Ui.text(o, Vector2(220, 496), msg, 15, Ui.ORANGE, 3)
