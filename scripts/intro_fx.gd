class_name IntroFx
extends RefCounted
# Drawing helpers for the cinematic intro (title card, skyline, stink cloud, VHS post effects).

const W := 960.0
const H := 540.0


static func hash1(i: float) -> float:
	return fposmod(sin(i * 12.9898) * 43758.5453, 1.0)


static func sky(ci: CanvasItem, top: Color, mid: Color, low: Color, horizon: float) -> void:
	var step := 10.0
	var y := 0.0
	while y < horizon:
		var k := y / horizon
		var c := top.lerp(mid, k * 2.0) if k < 0.5 else mid.lerp(low, (k - 0.5) * 2.0)
		ci.draw_rect(Rect2(-20, y, W + 40, step + 1.0), c)
		y += step


static func sun(ci: CanvasItem, c: Vector2, r: float) -> void:
	for i in 4:
		ci.draw_circle(c, r + 40.0 - i * 10.0, Color(1.0, 0.5, 0.3, 0.07))
	ci.draw_circle(c, r, Color(1.0, 0.78, 0.25))
	ci.draw_circle(c + Vector2(0, r * 0.25), r * 0.8, Color(1.0, 0.55, 0.35, 0.55))
	for i in 6:
		var y := c.y + r * 0.1 + i * r * 0.17
		ci.draw_rect(Rect2(c.x - r - 2, y, r * 2 + 4, 2.0 + i * 1.6), Color(0.95, 0.3, 0.5))


static func skyline(ci: CanvasItem, scroll: float, base_y: float, col: Color, seed_off: float, hmin: float, hmax: float, lit: bool, t: float) -> void:
	var n := 22
	var pitch := 78.0
	var period := n * pitch
	var off := -fposmod(scroll, period)
	for rep in 2:
		for i in n:
			var hh := hash1(i + seed_off)
			var bw := pitch * (0.8 + 0.5 * hash1(i * 3.1 + seed_off))
			var bh := hmin + (hmax - hmin) * hh
			var x := off + rep * period + i * pitch
			if x > W + 10.0 or x + bw < -10.0:
				continue
			ci.draw_rect(Rect2(x, base_y - bh, bw, bh + 200.0), col)
			if hash1(i * 7.7 + seed_off) > 0.6:
				ci.draw_rect(Rect2(x + bw * 0.45, base_y - bh - 22.0, 2.0, 22.0), col)
				ci.draw_circle(Vector2(x + bw * 0.45 + 1.0, base_y - bh - 22.0), 2.5, Color(1.0, 0.2, 0.3, 0.6 + 0.4 * sin(t * 4.0 + i)))
			if lit:
				var cols := int(bw / 14.0)
				var rows := int(bh / 18.0)
				for cx in cols:
					for cy in rows:
						var hv := hash1(i * 31.0 + cx * 5.0 + cy * 17.0 + seed_off)
						if hv > 0.72:
							var wc := Color(1.0, 0.35, 0.65) if hv > 0.88 else Color(0.35, 0.95, 1.0)
							wc.a = 0.55 + 0.35 * sin(t * 2.0 + hv * 40.0)
							ci.draw_rect(Rect2(x + 5.0 + cx * 14.0, base_y - bh + 8.0 + cy * 18.0, 6, 8), wc)


static func stink(ci: CanvasItem, t: float, strength: float) -> void:
	for i in 16:
		var x := fposmod(i * 131.0 + t * (22.0 + hash1(i) * 20.0), W + 500.0) - 250.0
		var y := 70.0 + (i % 6) * 48.0 + sin(t * 0.7 + i) * 14.0
		var r := 55.0 + hash1(i * 2.3) * 50.0
		var a := strength * (0.10 + 0.05 * hash1(i * 5.1))
		for k in 4:
			ci.draw_circle(Vector2(x, y), r * (1.0 - k * 0.2), Color(0.35, 0.85, 0.18, a))


static func boy_silhouette(ci: CanvasItem, p: Vector2, t: float) -> void:
	var col := Color(0.03, 0.0, 0.07)
	var sw := sin(t * 6.0)
	var bob := absf(sw) * 2.0
	var hip := p + Vector2(0, -34 - bob)
	var head := hip + Vector2(0, -34)
	ci.draw_line(hip, hip + Vector2(sw * 10.0, 34 + bob), col, 7.0)
	ci.draw_line(hip, hip + Vector2(-sw * 10.0, 34 + bob), col, 7.0)
	ci.draw_line(hip, head + Vector2(0, 8), col, 12.0)
	ci.draw_line(head + Vector2(0, 12), head + Vector2(-sw * 9.0, 30), col, 5.0)
	ci.draw_line(head + Vector2(0, 12), head + Vector2(sw * 9.0, 30), col, 5.0)
	ci.draw_circle(head, 11.0, col)
	for i in 3:
		var pts := PackedVector2Array()
		for j in 8:
			pts.append(head + Vector2((i - 1) * 14.0 + sin(t * 3.0 + j * 0.9 + i) * 5.0, -18.0 - j * 6.0))
		ci.draw_polyline(pts, Color(0.4, 0.95, 0.2, 0.55), 2.0)


static func glow_text(ci: CanvasItem, cx: float, y: float, s: String, fs: int, col: Color, glow: Color, sc: float, alpha: float) -> void:
	if alpha <= 0.0:
		return
	var w := Ui.text_width(s, fs)
	var tr := Loc.t(s)
	var f := ThemeDB.fallback_font
	ci.draw_set_transform(Vector2(cx, y), 0.0, Vector2(sc, sc))
	var pulse := 0.8 + 0.2 * sin(Time.get_ticks_msec() * 0.008)
	for ring: float in [10.0, 6.0, 3.0]:
		for k in 8:
			var d: Vector2 = Vector2.from_angle(TAU * k / 8.0) * ring
			ci.draw_string(f, Vector2(-w / 2.0, 0) + d, tr, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(glow.r, glow.g, glow.b, 0.10 * alpha * pulse))
	Ui.text(ci, Vector2(-w / 2.0, 0), s, fs, Color(col.r, col.g, col.b, alpha), 7)
	ci.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func wipe(ci: CanvasItem, k: float) -> void:
	if k <= 0.0 or k >= 1.0:
		return
	var x := lerpf(-400.0, W + 200.0, k)
	for band in [[0.0, Ui.PINK], [90.0, Ui.ORANGE], [160.0, Color(0.1, 0.0, 0.13)]]:
		var bx: float = x - band[0]
		ci.draw_colored_polygon(PackedVector2Array([Vector2(bx, -10), Vector2(bx + 140, -10), Vector2(bx + 60, H + 10), Vector2(bx - 80, H + 10)]), band[1])


static func vhs(ci: CanvasItem, t: float, flick: float, grain: float) -> void:
	var y := 0.0
	while y < H:
		ci.draw_rect(Rect2(0, y, W, 1.0), Color(0, 0, 0, 0.16))
		y += 3.0
	var band := fposmod(t * 90.0, H + 120.0) - 60.0
	ci.draw_rect(Rect2(0, band, W, 36), Color(1, 1, 1, 0.025 + 0.02 * flick))
	if flick > 0.0 and randf() < 0.35 * flick:
		ci.draw_rect(Rect2(0, 0, W, H), Color(0, 0, 0, randf() * 0.35 * flick))
	if flick > 0.0 and randf() < 0.1 * flick:
		var gy := randf() * H
		ci.draw_rect(Rect2(randf() * 60.0, gy, W, 3 + randf() * 5.0), Color(1, 1, 1, 0.12))
	for i in int(70.0 * grain):
		ci.draw_rect(Rect2(randf() * W, randf() * H, 2, 2), Color(1, 1, 1, 0.05 + randf() * 0.07))
