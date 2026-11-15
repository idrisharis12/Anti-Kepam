class_name Hud
extends Control
# Bottom bar on every page: GF face (emotion follows the clock), gas-cloud Kepam bar, items.

const H := 46.0
const BX := 290.0
const BW := 330.0
const BY := 10.0
const BH := 26.0

var t := 0.0
var shown := 0.0
var frame := Ui.box(Color(0.03, 0.0, 0.06), Color(0.55, 0.9, 0.25), 13, 3)


func _ready() -> void:
	position = Vector2(0, 540.0 - H)
	size = Vector2(960, H)
	z_index = 10
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	shown = GameState.spread


func _process(delta: float) -> void:
	t += delta
	shown = lerpf(shown, GameState.spread, minf(1.0, delta * 4.0))
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(0, 0, 960, H), Color(0.05, 0.0, 0.09, 0.93))
	draw_rect(Rect2(0, 0, 960, 3), Ui.PINK)
	_gf()
	_kepam()
	_items()


func _gf() -> void:
	var g := 1.0 - clampf(GameState.gf_left / GameState.GF_TIME, 0.0, 1.0)
	var mi := GfFace.mood_index(g)
	var ring: Color = [Color(1.0, 0.45, 0.7), Color(0.9, 0.55, 0.4), Color(0.45, 0.5, 0.9), Color(0.35, 0.45, 0.85), Color(0.5, 0.52, 0.58)][mi]
	var c := Vector2(40, 14)
	draw_circle(c, 33, Ui.INK)
	draw_circle(c, 30, ring.darkened(0.45))
	GfFace.draw_face(self, c, 26.0, g, t)
	draw_arc(c, 30, 0, TAU, 40, ring, 3.0, true)
	var left := int(maxf(GameState.gf_left, 0.0))
	Ui.text(self, Vector2(80, 18), "GF KAHWIN LAIN", 11, Color(1.0, 0.6, 0.78), 3)
	var urgent := left < 60 and int(t * 3.0) % 2 == 0
	Ui.text(self, Vector2(80, 40), "%d:%02d" % [floori(left / 60.0), left % 60], 22, Color(1.0, 0.35, 0.4) if urgent else Color.WHITE, 5)
	Ui.text(self, Vector2(152, 40), GfFace.MOODS[mi], 13, ring.lightened(0.3), 3)


func _kepam() -> void:
	var k := clampf(shown / 100.0, 0.0, 1.0)
	var shake := Vector2(randf_range(-1, 1), randf_range(-1, 1)) * 1.4 if k > 0.7 else Vector2.ZERO
	var bar := Rect2(BX, BY, BW, BH).grow(0)
	bar.position += shake
	draw_style_box(frame, bar)
	var fw := (BW - 8.0) * k
	var fx := bar.position.x + 4.0
	var fy := bar.position.y + 4.0
	var fh := BH - 8.0
	var col := Color(0.55, 0.92, 0.2).lerp(Color(0.38, 0.5, 0.1), k)
	if fw > 1.0:
		draw_rect(Rect2(fx, fy, fw, fh), col)
		draw_rect(Rect2(fx, fy, fw, fh * 0.3), Color(1, 1, 1, 0.14))
		var pr := fh * 0.34
		if fw > pr * 2.5:
			for i in 12:
				var px := pr + fmod(i * 41.0 + t * (12.0 + i * 2.0), fw - pr * 2.0)
				var py := fy + fh * 0.5 + sin(t * 2.2 + i * 1.7) * fh * 0.2
				var rr := pr + sin(t * 3.0 + i) * 1.5
				draw_circle(Vector2(fx + px, py), rr, Color(0.75, 1.0, 0.4, 0.28))
				draw_arc(Vector2(fx + px, py), rr, 0, TAU, 12, Color(0.2, 0.4, 0.05, 0.35), 1.0)
	for i in range(1, 4):
		draw_line(Vector2(bar.position.x + BW * i / 4.0, bar.position.y + 4), Vector2(bar.position.x + BW * i / 4.0, bar.position.y + BH - 4), Color(0, 0, 0, 0.35), 1.0)
	if k > 0.02:
		var fr := Vector2(fx + fw, fy + fh * 0.5)
		for i in 4:
			var o := Vector2(sin(t * 2.0 + i * 2.1) * 3.0, -sin(t * 3.0 + i) * 3.0 + (i - 1.5) * 4.0)
			var rr := fh * (0.55 + 0.1 * sin(t * 4.0 + i))
			draw_circle(fr + o + Vector2(rr * 0.3, 0), rr + 1.5, Color(0.12, 0.3, 0.05))
			draw_circle(fr + o + Vector2(rr * 0.3, 0), rr, Color(0.72, 0.95, 0.4, 0.95))
		for i in 3:
			var ph := fmod(t * 0.9 + i * 0.37, 1.0)
			draw_circle(fr + Vector2(8 + ph * 26.0, -4.0 - ph * 14.0 + i * 3.0), 3.0 * (1.0 - ph) + 1.0, Color(0.7, 1.0, 0.4, 0.8 * (1.0 - ph)))
	var tcol := Color(1.0, 0.4, 0.4) if (k > 0.7 and int(t * 4.0) % 2 == 0) else Color.WHITE
	Ui.text(self, Vector2(bar.position.x + 12, bar.position.y + 18), "KEPAM NEGERI", 12, tcol, 4)
	var pct := "%d%%" % int(shown)
	Ui.text(self, Vector2(bar.position.x + BW - 12 - Ui.text_width(pct, 14), bar.position.y + 19), pct, 14, tcol, 4)
	Ui.text(self, Vector2(BX, 43), "Gas kepam merebak ke seluruh negeri", 10, Color(0.75, 0.9, 0.5, 0.8), 0)


func _items() -> void:
	var x := 672.0
	Ui.germ(self, Vector2(x + 10, 24), 7.0, t)
	Ui.text(self, Vector2(x + 26, 30), str(GameState.kuman), 18, Color.WHITE, 4)
	Ui.soap(self, Vector2(x + 94, 24), 0.9)
	Ui.text(self, Vector2(x + 114, 30), str(GameState.soap), 18, Color.WHITE, 4)
	Ui.tissue(self, Vector2(x + 178, 25), 0.9)
	Ui.text(self, Vector2(x + 198, 30), str(GameState.tissue), 18, Color.WHITE, 4)
	Ui.text(self, Vector2(x, 44), "KUMAN", 9, Color(0.6, 0.9, 0.4), 0)
	Ui.text(self, Vector2(x + 82, 44), "SABUN", 9, Ui.WATER, 0)
	Ui.text(self, Vector2(x + 164, 44), "TISU", 9, Color(1, 0.9, 0.7), 0)
