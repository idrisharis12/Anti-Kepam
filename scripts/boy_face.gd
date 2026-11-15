class_name BoyFace
extends RefCounted
# The boy's face. g = 0 (hopeful) .. 1 (numb). Green stink tint grows with GameState.spread.

const INK := Color(0.1, 0.04, 0.08)
const MOODS := ["Berharap", "Risau", "Sedih", "Menangis", "Kosong"]


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


static func draw_portrait(ci: CanvasItem, c: Vector2, r: float, tex: Texture2D, tint: Color) -> void:
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	for i in 40:
		var a := TAU * i / 40.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
		uvs.append(Vector2(0.5 + cos(a) * 0.5, 0.5 + sin(a) * 0.5))
	ci.draw_colored_polygon(pts, tint, uvs, tex)


static func draw_face(ci: CanvasItem, c: Vector2, r: float, g: float, t: float) -> void:
	g = clampf(g, 0.0, 1.0)
	var numb := clampf((g - 0.84) / 0.1, 0.0, 1.0)
	var sad := clampf(g * 1.5, 0.0, 1.0)
	var tears := clampf((g - 0.45) / 0.3, 0.0, 1.0) * (1.0 - numb)
	var stink := clampf(GameState.spread / 100.0, 0.0, 1.0)
	var skin := Color(0.96, 0.8, 0.66).lerp(Color(0.62, 0.78, 0.38), stink * 0.55).lerp(Color(0.66, 0.7, 0.74), numb * 0.6)
	var hair := Color(0.42, 0.24, 0.13).lerp(Color(0.3, 0.3, 0.3), numb * 0.5)
	var hood := Color(0.25, 0.5, 0.28).lerp(Color(0.2, 0.3, 0.2), numb * 0.5)
	var fc := c + Vector2(0, r * 0.06)

	ci.draw_circle(c + Vector2(0, r * 0.98), r * 0.78, INK)
	ci.draw_circle(c + Vector2(0, r * 0.98), r * 0.7, hood)
	ci.draw_circle(c + Vector2(0, r * 0.62), r * 0.3, skin.darkened(0.15))
	ci.draw_circle(fc, r * 0.74, INK)
	ci.draw_circle(fc, r * 0.7, skin)
	for i in 9:
		var a := PI * (1.08 + 0.84 * i / 8.0)
		var tip := fc + Vector2(cos(a), sin(a)) * r * (0.92 + 0.14 * float(i % 2)) + Vector2(sin(t * 2.0 + i) * r * 0.02, 0)
		var base := fc + Vector2(cos(a), sin(a)) * r * 0.52
		ci.draw_line(base, tip, hair, maxf(2.0, r * 0.2))
	ci.draw_circle(fc + Vector2(0, -r * 0.38), r * 0.45, hair)
	ci.draw_colored_polygon(PackedVector2Array([fc + Vector2(-r * 0.62, -r * 0.1), fc + Vector2(-r * 0.2, -r * 0.34), fc + Vector2(r * 0.15, -r * 0.26), fc + Vector2(r * 0.62, -r * 0.1), fc + Vector2(r * 0.66, -r * 0.5), fc + Vector2(-r * 0.66, -r * 0.5)]), hair)

	var ey := c.y + r * 0.1
	var er := r * 0.13
	var blink := fmod(t + 0.7, 3.6) < 0.12
	for s in [-1.0, 1.0]:
		var ex: float = c.x + s * r * 0.27
		if numb > 0.0 and tears <= 0.0:
			ci.draw_arc(Vector2(ex, ey + er * 1.4), er * 1.1, 0.3, PI - 0.3, 8, Color(0.4, 0.4, 0.55, 0.6), maxf(1.0, r * 0.05))
		ci.draw_circle(Vector2(ex, ey), er, Color.WHITE)
		ci.draw_circle(Vector2(ex, ey + er * 0.25 * sad), er * 0.55, Color(0.12, 0.06, 0.04))
		ci.draw_arc(Vector2(ex, ey), er, 0.0, TAU, 14, INK, maxf(1.0, r * 0.04))
		var lid := 1.0 if blink else 0.0
		lid = maxf(lid, numb * 0.55)
		if lid > 0.0:
			ci.draw_rect(Rect2(ex - er - 1, ey - er - 1, er * 2 + 2, (er * 2 + 2) * lid), skin)
			ci.draw_line(Vector2(ex - er, ey - er + er * 2 * lid), Vector2(ex + er, ey - er + er * 2 * lid), INK, maxf(1.2, r * 0.05))
		if numb < 0.7:
			var inner := Vector2(c.x + s * r * 0.1, ey - er * (1.6 + 0.9 * sad))
			var outer := Vector2(c.x + s * r * 0.45, ey - er * (2.0 - 0.4 * sad))
			ci.draw_line(inner, outer, hair.darkened(0.3), maxf(1.8, r * 0.07))
		if tears > 0.0:
			var ph := fmod(t * 1.3 + (0.5 if s > 0 else 0.0), 1.0)
			var ty := ey + er + ph * r * 0.5 * tears
			ci.draw_circle(Vector2(ex, ty), maxf(1.3, r * 0.06), Color(0.55, 0.8, 1.0, 0.9 * (1.0 - ph)))
			ci.draw_line(Vector2(ex, ey + er), Vector2(ex, ty), Color(0.55, 0.8, 1.0, 0.5 * tears), maxf(1.0, r * 0.04))

	var w := r * 0.25
	var my := c.y + r * 0.5
	var a := r * 0.12 * (1.0 - 2.0 * sad) * (1.0 - numb)
	var prev := Vector2.ZERO
	for i in 9:
		var x := -w + 2.0 * w * i / 8.0
		var u := x / w
		var p := Vector2(c.x + x, my - a * (1.0 - u * u) + (r * 0.06 if a < 0.0 else 0.0))
		if i > 0:
			ci.draw_line(prev, p, INK, maxf(1.5, r * 0.06))
		prev = p


static func draw_mood(ci: CanvasItem, c: Vector2, r: float, mood: String, t: float) -> void:
	var g := {"happy": 0.0, "sad": 0.65, "shocked": 0.3}.get(mood, 0.0) as float
	draw_face(ci, c, r, g, t)
	if mood == "happy":
		ci.draw_arc(c + Vector2(0, r * 0.42), r * 0.26, 0.2, PI - 0.2, 12, INK, maxf(1.5, r * 0.07))
		for s in [-1.0, 1.0]:
			ci.draw_circle(c + Vector2(s * r * 0.45, r * 0.32), r * 0.1, Color(1.0, 0.5, 0.5, 0.55))
	elif mood == "shocked":
		ci.draw_circle(c + Vector2(0, r * 0.52), r * 0.12, INK)
		ci.draw_circle(c + Vector2(0, r * 0.52), r * 0.08, Color(0.5, 0.1, 0.15))
		var sx := c + Vector2(r * 0.78, -r * 0.5)
		ci.draw_line(sx, sx + Vector2(r * 0.2, -r * 0.15), Color(1, 0.9, 0.3), 2.0)
		ci.draw_line(sx + Vector2(0, r * 0.2), sx + Vector2(r * 0.25, r * 0.2), Color(1, 0.9, 0.3), 2.0)


static func draw_gf_mood(ci: CanvasItem, c: Vector2, r: float, tex: Texture2D, mood: String, t: float) -> void:
	var tint := Color.WHITE
	var off := Vector2.ZERO
	match mood:
		"sad":
			tint = Color(0.72, 0.76, 0.92)
			off = Vector2(0, sin(t * 2.0) * 1.5)
		"shocked":
			off = Vector2(sin(t * 38.0), cos(t * 31.0)) * 2.0
		_:
			off = Vector2(0, sin(t * 3.0) * 1.5)
	ci.draw_circle(c, r + 5, INK)
	draw_portrait(ci, c + off, r, tex, tint)
	if mood == "sad":
		var ph := fposmod(t * 1.1, 1.0)
		ci.draw_circle(c + Vector2(r * 0.3, -r * 0.05 + ph * r * 0.7), maxf(2.0, r * 0.06), Color(0.55, 0.8, 1.0, 1.0 - ph))
	elif mood == "shocked":
		ci.draw_string(ThemeDB.fallback_font, c + Vector2(r * 0.7, -r * 0.7), "!", HORIZONTAL_ALIGNMENT_LEFT, -1, int(r * 0.7), Color(1, 0.9, 0.3))
	else:
		for i in 3:
			var hc := c + Vector2(r * (0.8 + i * 0.12), -r * (0.5 + i * 0.28) - fposmod(t * 0.7 + i * 0.3, 1.0) * 6.0)
			ci.draw_circle(hc, 3.0, Color(1, 0.4, 0.55, 0.9))
