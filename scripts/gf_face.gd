class_name GfFace
extends RefCounted
# The girlfriend's face. g = 0 (hopeful) .. 1 (feels nothing). Drawn procedurally.

const INK := Color(0.1, 0.0, 0.13)
const MOODS := ["Berharap", "Kecewa", "Sedih", "Menangis", "Kosong"]


static func mood_index(g: float) -> int:
	if g < 0.25:
		return 0
	if g < 0.5:
		return 1
	if g < 0.75:
		return 2
	if g < 0.88:
		return 3
	return 4


static func draw_face(ci: CanvasItem, c: Vector2, r: float, g: float, t: float) -> void:
	g = clampf(g, 0.0, 1.0)
	var numb := clampf((g - 0.84) / 0.1, 0.0, 1.0)
	var sad := clampf(g * 1.5, 0.0, 1.0)
	var tears := clampf((g - 0.45) / 0.3, 0.0, 1.0) * (1.0 - numb)
	var skin := Color(1.0, 0.82, 0.7).lerp(Color(0.68, 0.73, 0.8), numb)
	var hair := Color(0.14, 0.06, 0.18).lerp(Color(0.2, 0.2, 0.25), numb)
	var fc := c + Vector2(0, r * 0.08)

	ci.draw_circle(c + Vector2(0, r * 0.05), r * 0.98, hair)
	ci.draw_rect(Rect2(c.x - r * 0.98, c.y, r * 0.4, r * 0.5), hair)
	ci.draw_rect(Rect2(c.x + r * 0.58, c.y, r * 0.4, r * 0.5), hair)
	ci.draw_circle(fc, r * 0.8, skin)
	ci.draw_arc(fc, r * 0.8, 0.0, TAU, 40, INK, maxf(1.5, r * 0.05), true)

	var pts := PackedVector2Array()
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(fc + Vector2(cos(a), sin(a)) * r * 0.82)
	pts.append(Vector2(c.x + r * 0.62, c.y - r * 0.12))
	pts.append(Vector2(c.x + r * 0.15, c.y - r * 0.32))
	pts.append(Vector2(c.x - r * 0.3, c.y - r * 0.2))
	pts.append(Vector2(c.x - r * 0.62, c.y - r * 0.02))
	ci.draw_colored_polygon(pts, hair)

	var ey := c.y + r * 0.1
	var er := r * 0.15
	var blink := fmod(t + 1.3, 3.8) < 0.12
	if numb > 0.0 and tears <= 0.0:
		for s in [-1.0, 1.0]:
			ci.draw_arc(Vector2(c.x + s * r * 0.3, ey + er * 1.3), er * 1.1, 0.3, PI - 0.3, 8, Color(0.45, 0.45, 0.6, 0.6), maxf(1.0, r * 0.05))
	if (1.0 - sad) > 0.0:
		for s in [-1.0, 1.0]:
			ci.draw_circle(Vector2(c.x + s * r * 0.5, ey + r * 0.28), r * 0.14, Color(1.0, 0.45, 0.55, 0.45 * (1.0 - sad)))
	for s in [-1.0, 1.0]:
		var ex: float = c.x + s * r * 0.3
		ci.draw_circle(Vector2(ex, ey), er, Color.WHITE)
		ci.draw_circle(Vector2(ex, ey + er * 0.25 * sad), er * 0.55, Color(0.12, 0.06, 0.1))
		ci.draw_circle(Vector2(ex - er * 0.15, ey + er * 0.25 * sad - er * 0.2), er * 0.18, Color.WHITE)
		ci.draw_arc(Vector2(ex, ey), er, 0.0, TAU, 14, INK, maxf(1.0, r * 0.04))
		var lid := 0.0
		if blink:
			lid = 1.0
		lid = maxf(lid, numb * 0.55)
		if lid > 0.0:
			ci.draw_rect(Rect2(ex - er - 1, ey - er - 1, er * 2 + 2, (er * 2 + 2) * lid), skin)
			ci.draw_line(Vector2(ex - er, ey - er + er * 2 * lid), Vector2(ex + er, ey - er + er * 2 * lid), INK, maxf(1.2, r * 0.05))
		if numb < 0.7:
			var inner := Vector2(c.x + s * r * 0.14, ey - er * (1.7 + 0.7 * sad))
			var outer := Vector2(c.x + s * r * 0.5, ey - er * (1.9 - 0.5 * sad))
			ci.draw_line(inner, outer, hair.lightened(0.1), maxf(1.8, r * 0.07))

	var w := r * 0.28
	var my := c.y + r * 0.5
	var a := r * 0.12 * (1.0 - 2.0 * sad) * (1.0 - numb)
	if tears > 0.4:
		a -= sin(t * 14.0) * r * 0.02
	var prev := Vector2.ZERO
	for i in 9:
		var x := -w + 2.0 * w * i / 8.0
		var p := Vector2(c.x + x, my + a * (1.0 - pow(x / w, 2.0)))
		if i > 0:
			ci.draw_line(prev, p, INK, maxf(1.8, r * 0.06))
		prev = p

	if tears > 0.0:
		for s in [-1.0, 1.0]:
			var ex: float = c.x + s * r * 0.3
			var top := ey + er * 0.9
			var ln := r * 0.6 * tears
			ci.draw_line(Vector2(ex, top), Vector2(ex + s * r * 0.04, top + ln), Color(0.55, 0.85, 1.0, 0.75), maxf(1.5, r * 0.07))
			var d := fmod(t * r * 1.4 + (s + 1.0) * r * 0.3, ln + r * 0.15)
			ci.draw_circle(Vector2(ex + s * r * 0.04 * (d / maxf(ln, 1.0)), top + d), maxf(1.5, r * 0.065), Color(0.7, 0.92, 1.0))
