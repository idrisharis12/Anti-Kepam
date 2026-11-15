class_name Fx
extends RefCounted
# Shared visual helpers: hub dusk tint, neon flicker, squish shake, lipas and splat drawing, sparkles, bubbles.


static func dusk(ratio: float) -> Color:
	var k := 1.0 - clampf(ratio, 0.0, 1.0)
	if k < 0.5:
		return Color.WHITE.lerp(Color(1.0, 0.8, 0.65), k * 2.0)
	return Color(1.0, 0.8, 0.65).lerp(Color(0.6, 0.52, 0.85), (k - 0.5) * 2.0)


static func dusk_now() -> Color:
	return dusk(GameState.gf_left / GameState.GF_TIME)


static func neon(base: Color, t: float, i := 0) -> Color:
	var f := 0.82 + 0.18 * sin(t * 6.0 + i * 1.7)
	if fmod(t * 0.9 + i * 0.37, 5.0) < 0.12:
		f *= 0.3
	return Color(base.r * f, base.g * f, base.b * f, base.a)


static func squish(n: Node2D, strength := 0.4) -> void:
	var s0 := n.scale
	var p0 := n.position
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector2(s0.x * (1.0 + strength), s0.y * (1.0 - strength)), 0.06)
	tw.tween_property(n, "scale", s0, 0.2).set_trans(Tween.TRANS_ELASTIC)
	var sh := n.create_tween()
	for i in 5:
		sh.tween_property(n, "position", p0 + Vector2(randf_range(-4.0, 4.0), randf_range(-3.0, 3.0)), 0.03)
	sh.tween_property(n, "position", p0, 0.03)


static func _ellipse(c: Vector2, rx: float, ry: float, rot: float) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in 20:
		var a := TAU * i / 20.0
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry).rotated(rot))
	return pts


static func draw_lipas(ci: CanvasItem, c: Vector2, s: float, t: float, dead := false, rot := 0.0) -> void:
	var ink := Color(0.12, 0.05, 0.02)
	var body := Color(0.45, 0.22, 0.08) if not dead else Color(0.3, 0.18, 0.1)
	for side in [-1.0, 1.0]:
		for i in 3:
			var w := 0.0 if dead else sin(t * 18.0 + i * 2.0 + side) * 0.25
			var base := c + Vector2(side * 6.0 * s, (i - 1) * 7.0 * s).rotated(rot)
			var knee := base + Vector2(side * (10.0 + i * 2.0) * s, (i - 1) * 4.0 * s + w * 8.0 * s).rotated(rot)
			var foot := knee + Vector2(side * 8.0 * s, (i - 1) * 7.0 * s + (-10.0 * s if dead else 4.0 * s)).rotated(rot)
			ci.draw_polyline(PackedVector2Array([base, knee, foot]), ink, maxf(1.0, 1.6 * s))
	for side in [-1.0, 1.0]:
		var wob := 0.0 if dead else sin(t * 9.0 + side) * 4.0 * s
		var a0 := c + Vector2(side * 3.0 * s, -18.0 * s).rotated(rot)
		ci.draw_polyline(PackedVector2Array([a0, a0 + Vector2(side * 10.0 * s + wob, -14.0 * s).rotated(rot), a0 + Vector2(side * 22.0 * s + wob, -20.0 * s).rotated(rot)]), ink, maxf(1.0, 1.2 * s))
	ci.draw_colored_polygon(_ellipse(c, 11.0 * s, 18.0 * s, rot), ink)
	ci.draw_colored_polygon(_ellipse(c, 9.5 * s, 16.5 * s, rot), body)
	ci.draw_line(c + Vector2(0, -14.0 * s).rotated(rot), c + Vector2(0, 14.0 * s).rotated(rot), body.darkened(0.4), maxf(1.0, 1.2 * s))
	ci.draw_colored_polygon(_ellipse(c + Vector2(-3.5 * s, -6.0 * s).rotated(rot), 2.2 * s, 6.0 * s, rot), Color(1, 0.8, 0.5, 0.45))
	ci.draw_colored_polygon(_ellipse(c + Vector2(0, -18.0 * s).rotated(rot), 6.0 * s, 5.0 * s, rot), ink)
	ci.draw_colored_polygon(_ellipse(c + Vector2(0, -18.0 * s).rotated(rot), 4.8 * s, 3.8 * s, rot), body.darkened(0.15))
	if not dead:
		for side in [-1.0, 1.0]:
			ci.draw_circle(c + Vector2(side * 2.2 * s, -19.0 * s).rotated(rot), 1.2 * s, Color(1, 0.2, 0.15))
	else:
		for side in [-1.0, 1.0]:
			var e := c + Vector2(side * 2.2 * s, -19.0 * s).rotated(rot)
			ci.draw_line(e + Vector2(-1.2, -1.2) * s, e + Vector2(1.2, 1.2) * s, Color(1, 1, 1), 1.0)
			ci.draw_line(e + Vector2(-1.2, 1.2) * s, e + Vector2(1.2, -1.2) * s, Color(1, 1, 1), 1.0)


static func draw_splat(ci: CanvasItem, c: Vector2, k: float, t: float) -> void:
	k = clampf(k, 0.0, 1.0)
	var col := Color(0.75, 0.8, 0.2, 0.9 * (1.0 - 0.4 * k))
	ci.draw_circle(c, 14.0 + 8.0 * k, col)
	ci.draw_circle(c + Vector2(3, -2), 8.0, Color(0.95, 0.9, 0.4, 0.8))
	for i in 9:
		var a := TAU * i / 9.0 + 0.3
		var d := Vector2(cos(a), sin(a)) * (22.0 + (i % 3) * 8.0) * (0.5 + 0.5 * k)
		ci.draw_circle(c + d, 3.0 + (i % 3), col)
		ci.draw_line(c + d * 0.4, c + d * 0.9, col, 2.0)
	ci.draw_arc(c, 30.0 * k + 6.0, 0, TAU, 24, Color(1, 1, 1, 0.5 * (1.0 - k)), 2.0)


static func sparkles(ci: CanvasItem, rect: Rect2, t: float, k: float, n: int) -> void:
	for i in n:
		var px := rect.position.x + fposmod(i * 97.3 + sin(t * 0.4 + i) * 20.0, rect.size.x)
		var py := rect.position.y + fposmod(i * 53.7 + cos(t * 0.5 + i * 1.3) * 10.0, rect.size.y)
		var tw := 0.5 + 0.5 * sin(t * 4.0 + i * 1.9)
		var r := (2.0 + (i % 3) * 1.4) * (0.5 + tw) * k
		var col := Color(1.0, 0.96, 0.6, 0.85 * tw * k)
		ci.draw_circle(Vector2(px, py), r, col)
		ci.draw_line(Vector2(px - r * 2.4, py), Vector2(px + r * 2.4, py), col, 1.4)
		ci.draw_line(Vector2(px, py - r * 2.4), Vector2(px, py + r * 2.4), col, 1.4)


static func bubbles(ci: CanvasItem, c: Vector2, k: float, t: float) -> void:
	var n := int(4.0 + k * 16.0)
	for i in n:
		var ph := fposmod(t * (0.4 + (i % 4) * 0.1) + i * 0.173, 1.0)
		var x := c.x + sin(i * 2.3 + t * 1.5) * (26.0 + k * 20.0)
		var y := c.y + 50.0 - ph * (110.0 + k * 30.0)
		var r := (3.0 + (i % 4) * 2.0) * (0.5 + 0.7 * k)
		ci.draw_circle(Vector2(x, y), r, Color(1, 1, 1, 0.25 * (1.0 - ph)))
		ci.draw_arc(Vector2(x, y), r, 0, TAU, 12, Color(0.8, 0.95, 1.0, 0.8 * (1.0 - ph)), 1.5)
		ci.draw_circle(Vector2(x - r * 0.35, y - r * 0.35), maxf(1.0, r * 0.22), Color(1, 1, 1, 0.9 * (1.0 - ph)))


static func draw_newspaper(ci: CanvasItem, r: Rect2, head: String, sub: String, a: float, rot := -0.05) -> void:
	ci.draw_set_transform(r.get_center(), rot, Vector2.ONE)
	var rr := Rect2(-r.size / 2.0, r.size)
	ci.draw_rect(Rect2(rr.position + Vector2(6, 8), rr.size), Color(0, 0, 0, 0.5 * a))
	ci.draw_rect(rr, Color(0.93, 0.9, 0.8, a))
	ci.draw_rect(rr, Color(0.1, 0.08, 0.06, a), false, 3.0)
	Ui.text(ci, rr.position + Vector2(rr.size.x / 2.0 - Ui.text_width("BERITA KEPAM 26", 22) / 2.0, 34), "BERITA KEPAM 26", 22, Color(0.1, 0.08, 0.06, a), 0)
	ci.draw_line(rr.position + Vector2(10, 46), rr.position + Vector2(rr.size.x - 10, 46), Color(0.1, 0.08, 0.06, a), 3.0)
	var h := Loc.t(head)
	var fs := 30 if Ui.text_width(h, 30) < rr.size.x - 24 else 22
	Ui.text(ci, rr.position + Vector2(rr.size.x / 2.0 - Ui.text_width(h, fs) / 2.0, 92), h, fs, Color(0.7, 0.05, 0.08, a), 0)
	var s := Loc.t(sub)
	Ui.text(ci, rr.position + Vector2(rr.size.x / 2.0 - Ui.text_width(s, 14) / 2.0, 124), s, 14, Color(0.2, 0.15, 0.1, a), 0)
	for i in 5:
		ci.draw_rect(Rect2(rr.position + Vector2(14 + (i % 2) * 8, 144 + i * 16), Vector2(rr.size.x * 0.58 - (i % 3) * 16, 5)), Color(0.35, 0.3, 0.25, 0.7 * a))
	ci.draw_rect(Rect2(rr.position + Vector2(rr.size.x * 0.64, 144), Vector2(rr.size.x * 0.32, 74)), Color(0.45, 0.5, 0.35, 0.8 * a))
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
