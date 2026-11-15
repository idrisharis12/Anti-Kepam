class_name ComicStrip
extends Node2D
# Four-panel backstory shown before the first station. ENTER or click skips. Emits finished.

signal finished

const PANELS := ["comic_1", "comic_2", "comic_3", "comic_4"]
const PW := 200.0
const PH := 250.0
const GAP := 18.0

var t := 0.0
var shown := 0.0
var done := false
var ov := Overlay.new()


func _ready() -> void:
	z_index = 50
	ov.painter = _paint
	add_child(ov)


func _process(delta: float) -> void:
	t += delta
	shown = minf(shown + delta / 1.7, float(PANELS.size()) + 1.6)
	if shown >= PANELS.size() + 1.5:
		_finish()


func _input(event: InputEvent) -> void:
	var skip: bool = event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER or event.keycode == KEY_SPACE)
	if event is InputEventMouseButton and event.pressed:
		skip = true
	if skip:
		_finish()


func _finish() -> void:
	if done:
		return
	done = true
	finished.emit()
	queue_free()


func _paint(o: Overlay) -> void:
	o.draw_rect(Rect2(0, 0, 960, 540), Color(0.08, 0.02, 0.12))
	var title := Story.line("comic_title")
	Ui.text(o, Vector2(480 - Ui.text_width(title, 34) / 2.0, 70), title, 34, Ui.ORANGE, 8)
	var total := PANELS.size() * PW + (PANELS.size() - 1) * GAP
	var x0 := 480.0 - total / 2.0
	for i in PANELS.size():
		var a := clampf(shown - i, 0.0, 1.0)
		if a <= 0.0:
			continue
		var r := Rect2(x0 + i * (PW + GAP), 100.0 + (1.0 - a) * 20.0, PW, PH)
		o.draw_rect(Rect2(r.position + Vector2(5, 6), r.size), Color(0, 0, 0, 0.5 * a))
		o.draw_rect(r, Color(0.98, 0.93, 0.8, a))
		_scene(o, i, r, a)
		o.draw_rect(r, Color(0.08, 0.04, 0.1, a), false, 4.0)
		var cap := Story.line(PANELS[i])
		var cr := Rect2(r.position.x + 6, r.end.y - 52, r.size.x - 12, 46)
		o.draw_rect(cr, Color(1.0, 0.95, 0.6, a))
		o.draw_rect(cr, Color(0.08, 0.04, 0.1, a), false, 2.0)
		_wrapped(o, cap, cr, 13, Color(0.1, 0.05, 0.1, a))
	var sk := Story.line("comic_skip")
	Ui.text(o, Vector2(940 - Ui.text_width(sk, 13), 520), sk, 13, Color(0.7, 0.7, 0.8), 3)


func _wrapped(o: Overlay, s: String, r: Rect2, fs: int, col: Color) -> void:
	var words := s.split(" ")
	var line := ""
	var y := r.position.y + fs + 6.0
	for w in words:
		var tryl := w if line == "" else line + " " + w
		if Ui.text_width(tryl, fs) > r.size.x - 12.0 and line != "":
			Ui.text(o, Vector2(r.position.x + 8, y), line, fs, col, 0)
			y += fs + 4.0
			line = w
		else:
			line = tryl
	if line != "":
		Ui.text(o, Vector2(r.position.x + 8, y), line, fs, col, 0)


func _scene(o: Overlay, i: int, r: Rect2, a: float) -> void:
	var c := r.position + Vector2(r.size.x / 2.0, 90.0)
	var sky: Color = [Color(0.55, 0.7, 0.9), Color(0.15, 0.1, 0.35), Color(0.7, 0.5, 0.4), Color(0.45, 0.65, 0.3)][i]
	sky.a = a
	o.draw_rect(Rect2(r.position + Vector2(4, 4), Vector2(r.size.x - 8, r.size.y - 60)), sky)
	match i:
		0:
			o.draw_rect(Rect2(c + Vector2(-60, 30), Vector2(120, 40)), Color(0.45, 0.3, 0.2, a))
			for k in 3:
				o.draw_rect(Rect2(c + Vector2(-50 + k * 34, 14), Vector2(26, 18)), Color(0.9, 0.9, 0.95, a))
			BoyFace.draw_face(o, c + Vector2(0, -18), 36.0, 0.45, t)
			Ui.text(o, c + Vector2(-60, -64), "EXAM", 16, Color(0.8, 0.1, 0.1, a), 0)
		1:
			o.draw_rect(Rect2(c + Vector2(-50, 10), Vector2(100, 56)), Color(0.05, 0.05, 0.1, a))
			o.draw_rect(Rect2(c + Vector2(-44, 16), Vector2(88, 44)), Color(0.3, 0.8, 1.0, a * (0.7 + 0.3 * sin(t * 6.0))))
			BoyFace.draw_face(o, c + Vector2(0, -26), 34.0, 0.6, t)
			Ui.text(o, c + Vector2(30, -50), "05:30", 14, Color(1, 1, 1, a), 0)
		2:
			BoyFace.draw_face(o, c + Vector2(0, -8), 40.0, 0.75, t)
			for k in 3:
				o.draw_line(c + Vector2(-34 + k * 34, 30), c + Vector2(-34 + k * 34 + sin(t * 3.0 + k) * 5.0, -50), Color(0.5, 0.9, 0.2, a * 0.7), 4.0)
		3:
			BoyFace.draw_face(o, c + Vector2(0, -8), 40.0, 0.9, t)
			for k in 4:
				var ang := t * 2.0 + k * 1.6
				var fp := c + Vector2(cos(ang), sin(ang * 1.3)) * 56.0
				o.draw_circle(fp, 2.4, Color(0.05, 0.05, 0.05, a))
			Ui.text(o, c + Vector2(-26, 62), "bzzz", 13, Color(0.1, 0.1, 0.1, a), 0)
