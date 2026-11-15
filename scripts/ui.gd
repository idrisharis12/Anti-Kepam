class_name Ui
extends RefCounted

const PINK := Color(1.0, 0.25, 0.55)
const ORANGE := Color(1.0, 0.72, 0.15)
const GREEN := Color(0.2, 0.92, 0.42)
const WATER := Color(0.5, 0.86, 1.0)
const INK := Color(0.1, 0.0, 0.13)
const CREAM := Color(1.0, 0.95, 0.85)


static func box(fill: Color, border: Color, radius := 8, bw := 3) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.set_border_width_all(bw)
	s.border_color = border
	s.set_corner_radius_all(radius)
	return s


static func panel(parent: Node, rect: Rect2, border := PINK) -> Panel:
	var p := Panel.new()
	p.position = rect.position
	p.size = rect.size
	var sb := box(Color(0.08, 0.015, 0.14, 0.96), border, 8, 4)
	sb.shadow_color = Color(0, 0, 0, 0.55)
	sb.shadow_size = 10
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(p)
	return p


static func label(parent: Node, text: String, pos: Vector2, fs: int, col: Color, w := 380.0, center := true) -> Label:
	var l := Label.new()
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = w
	l.text = text
	l.position = pos
	l.size = Vector2(w, fs * 1.4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if center else HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_font_size_override("font_size", fs)
	l.add_theme_color_override("font_color", col)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", maxi(2, fs / 6))
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l


static func rule(parent: Node, pos: Vector2, w: float, col := PINK) -> void:
	var r := ColorRect.new()
	r.color = col
	r.position = pos
	r.size = Vector2(w, 3)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)


static func text(ci: CanvasItem, pos: Vector2, s: String, fs: int, col: Color, outline := 4) -> void:
	s = Loc.t(s)
	var f := ThemeDB.fallback_font
	if outline > 0:
		ci.draw_string_outline(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, outline, INK)
	ci.draw_string(f, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


static func text_width(s: String, fs: int) -> float:
	s = Loc.t(s)
	return ThemeDB.fallback_font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x


static func germ(ci: CanvasItem, c: Vector2, r: float, t := 0.0) -> void:
	var dark := Color(0.12, 0.3, 0.05)
	for i in 8:
		var a := TAU * i / 8.0 + t * 0.8
		var d := Vector2(cos(a), sin(a))
		ci.draw_line(c + d * r * 0.8, c + d * r * 1.35, dark, maxf(1.5, r * 0.22))
		ci.draw_circle(c + d * r * 1.35, maxf(1.2, r * 0.17), dark)
	ci.draw_circle(c, r + 1.5, dark)
	ci.draw_circle(c, r, Color(0.5, 0.88, 0.2))
	ci.draw_circle(c + Vector2(-r * 0.3, -r * 0.35), r * 0.28, Color(0.8, 1.0, 0.5, 0.8))
	for s in [-1.0, 1.0]:
		ci.draw_circle(c + Vector2(s * r * 0.36, -r * 0.1), r * 0.27, Color.WHITE)
		ci.draw_circle(c + Vector2(s * r * 0.36, -r * 0.05), r * 0.13, Color(0.1, 0.05, 0.1))
	ci.draw_arc(c + Vector2(0, r * 0.35), r * 0.28, 0.2, PI - 0.2, 8, dark, maxf(1.2, r * 0.1))


static func soap(ci: CanvasItem, c: Vector2, s := 1.0) -> void:
	var r := Rect2(c - Vector2(13, 9) * s, Vector2(26, 18) * s)
	ci.draw_style_box(box(Color(0.45, 0.8, 1.0), INK, int(6 * s), 2), r)
	ci.draw_rect(Rect2(r.position + Vector2(4, 3) * s, Vector2(10, 3) * s), Color(1, 1, 1, 0.7))
	ci.draw_circle(c + Vector2(15, -12) * s, 4 * s, Color(1, 1, 1, 0.75))
	ci.draw_circle(c + Vector2(20, -6) * s, 2.5 * s, Color(1, 1, 1, 0.6))


static func tissue(ci: CanvasItem, c: Vector2, s := 1.0) -> void:
	var r := Rect2(c - Vector2(12, 10) * s, Vector2(24, 20) * s)
	ci.draw_style_box(box(Color(1.0, 0.95, 0.82), INK, int(4 * s), 2), r)
	ci.draw_line(c + Vector2(-6, -2) * s, c + Vector2(6, -2) * s, Color(0.8, 0.7, 0.55), 2)
	ci.draw_line(c + Vector2(-6, 3) * s, c + Vector2(4, 3) * s, Color(0.8, 0.7, 0.55), 2)
	var pts := PackedVector2Array([c + Vector2(-4, -10) * s, c + Vector2(2, -17) * s, c + Vector2(8, -10) * s])
	ci.draw_colored_polygon(pts, Color(1.0, 0.98, 0.9))
