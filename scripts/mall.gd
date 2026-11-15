extends ShowerBase
# Shopping mall: a lipas (cockroach) hunts the boy through a dark maze. Run to the toilet (TANDAS) at the far end,
# spray the lipas dead, then hold SPACE to wash. Caught by the lipas = viral.

const T := 28
const ORIGIN := Vector2(20, 84)
const MAP := [
	"######################",
	"#S...#.......#.......#",
	"#.##.#.#####.#.#####.#",
	"#.#..#.#...#...#...#.#",
	"#.#.##.#.#.#####.#.#.#",
	"#.#....#.#.......#...#",
	"#.######.#######.#####",
	"#........#.....#.....#",
	"#.######.#.###.#.###.#",
	"#.#....#...#.....#...#",
	"#.#.##.#####.#####.#.#",
	"#...#........#.....#E#",
	"######################",
]
const PLAYER_SPEED := 108.0
const LIPAS_SPEED := 74.0
const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var walls := {}
var exit_cell := Vector2i.ZERO
var exit_dist := {}
var player := ColorRect.new()
var avatar := AvatarView.new()
var lipas_pos := Vector2.ZERO
var lipas_delay := 3.0
var near_lipas := 0.0
var scare := 0.0
var scene_t := 0.0
var inside := false
var inside_t := 0.0
var shower_on := false
var lipas_dead := false
var skitter_t := 0.0
var spraying := false
var spray_sfx := false
var rush_from := Vector2.ZERO
var lipas_dir := Vector2.LEFT
var fog_flicker := 1.0
var hiding := false
var hide_t := 0.0
var hide_cd := 0.0
var last_seen := Vector2i.ZERO
const HIDE_SPOTS := [Vector2i(4, 3), Vector2i(14, 5), Vector2i(12, 9), Vector2i(18, 3), Vector2i(5, 9)]
const HIDE_MAX := 3.0
const HIDE_COOLDOWN := 9.0


func _build() -> void:
	station_id = "mall"
	NpcChat.show_on(self, "mall_guard")
	Sfx.play_music("mall")
	Sfx.play("ghost")
	time_limit = 0.0
	bg.color = Color(0.04, 0.015, 0.07)
	var tex := AtlasTexture.new()
	tex.atlas = load("res://assets/mall_bg.png")
	tex.region = Rect2(0, 150, 1024, 710)
	var img := TextureRect.new()
	img.texture = tex
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.size = Vector2(960, 540)
	img.modulate = Color(0.3, 0.28, 0.4)
	add_child(img)
	move_child(img, 1)
	for l in [title, status, body]:
		l.visible = false
	var head := Ui.label(self, "SHOPPING MALL", Vector2(20, 12), 30, Ui.ORANGE, 616)
	head.add_theme_constant_override("outline_size", 8)
	Ui.label(self, "Lipas kejar! Lari ke TANDAS", Vector2(20, 54), 14, Ui.PINK, 616)
	var side := Ui.panel(self, Rect2(656, 10, 288, 474), Ui.PINK)
	move_child(side, 2)

	var start := Vector2i(1, 1)
	for y in MAP.size():
		for x in MAP[y].length():
			var c: String = MAP[y][x]
			if c == "#":
				walls[Vector2i(x, y)] = true
			elif c == "S":
				start = Vector2i(x, y)
			elif c == "E":
				exit_cell = Vector2i(x, y)
	exit_dist = _bfs(exit_cell)

	player.color = Color(0, 0, 0, 0)
	player.size = Vector2(16, 16)
	player.position = _center(start) - player.size / 2.0
	add_child(player)
	lipas_pos = _center(Vector2i(16, 5))
	avatar.scale = Vector2(0.45, 0.45)
	avatar.z_index = 4
	avatar.dirt = 0.55
	add_child(avatar)

	var world := Overlay.new()
	world.painter = _paint_world
	world.z_index = 3
	add_child(world)
	var fog := Overlay.new()
	fog.painter = _paint_fog
	fog.z_index = 5
	add_child(fog)
	var top := Overlay.new()
	top.painter = _paint_top
	top.z_index = 6
	add_child(top)


func _center(c: Vector2i) -> Vector2:
	return ORIGIN + (Vector2(c) + Vector2(0.5, 0.5)) * T


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(((p - ORIGIN) / T).floor())


func _bfs(from: Vector2i) -> Dictionary:
	var d := {from: 0}
	var q: Array[Vector2i] = [from]
	var i := 0
	while i < q.size():
		var c: Vector2i = q[i]
		i += 1
		for dir in DIRS:
			var n: Vector2i = c + dir
			if walls.has(n) or d.has(n) or n.x < 0 or n.y < 0 or n.x >= MAP[0].length() or n.y >= MAP.size():
				continue
			d[n] = d[c] + 1
			q.append(n)
	return d


func _blocked(p: Vector2, s: Vector2) -> bool:
	for corner in [p, p + Vector2(s.x, 0), p + Vector2(0, s.y), p + s]:
		if walls.has(_cell(corner)):
			return true
	return false


func _move_player(dir: Vector2, delta: float) -> void:
	var step := dir * PLAYER_SPEED * delta
	var nx := player.position + Vector2(step.x, 0)
	if not _blocked(nx, player.size):
		player.position = nx
	var ny := player.position + Vector2(0, step.y)
	if not _blocked(ny, player.size):
		player.position = ny


func _player_center() -> Vector2:
	return player.position + player.size / 2.0


func can_wash() -> bool:
	return shower_on


func _move_lipas(target_cell: Vector2i, delta: float) -> void:
	var gc := _cell(lipas_pos)
	var dist := _bfs(target_cell)
	var best := gc
	var bd: int = dist.get(gc, 9999)
	for dir in DIRS:
		var n: Vector2i = gc + dir
		if dist.has(n) and dist[n] < bd:
			bd = dist[n]
			best = n
	var target := _center(best)
	if best == gc:
		target = _center(target_cell)
	lipas_pos = lipas_pos.move_toward(target, LIPAS_SPEED * Difficulty.lipas_mult() * (0.55 if hiding else 1.0) * delta)


func _tick(delta: float) -> void:
	scene_t += delta
	var pc := _cell(_player_center())
	if not inside and pc == exit_cell:
		inside = true
		inside_t = 0.0
		current = 0
		near_lipas = 0.0
		rush_from = lipas_pos
		player.position = _center(exit_cell) - player.size / 2.0
		Sfx.play("click")
	if inside:
		_inside_tick(delta)
	else:
		_move_player(GameState.move_vec(), delta)
		if elapsed > lipas_delay:
			var prev := lipas_pos
			_move_lipas(pc, delta)
			if lipas_pos.distance_to(prev) > 0.01:
				lipas_dir = (lipas_pos - prev).normalized()
			var gd: int = _bfs(pc).get(_cell(lipas_pos), 99)
			near_lipas = clampf(1.0 - float(gd) / 8.0, 0.0, 1.0)
			scare += delta * near_lipas
			Sfx.set_tension(near_lipas)
			if near_lipas > 0.8:
				Flow.buzz(30)
			skitter_t -= delta
			if skitter_t <= 0.0:
				skitter_t = lerpf(0.55, 0.13, near_lipas)
				Sfx.play("skitter", lerpf(-22.0, -2.0, near_lipas), randf_range(0.9, 1.15))
			if (_player_center() - lipas_pos).length() < 17.0:
				done = true
				Sfx.play("fail")
				GameState.lose("viral")
				return
		else:
			near_lipas = 0.0
	fog_flicker = 1.0 if near_lipas < 0.3 else (0.75 + 0.25 * sin(scene_t * 31.0) * randf())
	avatar.position = _player_center() + Vector2(0, 14)
	avatar.modulate.a = 0.25 if hiding else 1.0
	var mean := 0.0
	for p in progress:
		mean += p
	avatar.dirt = clampf(0.55 - mean / PARTS.size() * 0.55, 0.0, 1.0)


func _hide_tick(delta: float, pc: Vector2i) -> void:
	hide_cd = maxf(0.0, hide_cd - delta)
	if hiding:
		hide_t += delta
		if hide_t >= HIDE_MAX or GameState.move_vec() != Vector2.ZERO:
			hiding = false
			hide_cd = HIDE_COOLDOWN
		return
	if hide_cd > 0.0 or not (Input.is_key_pressed(KEY_H) or Input.is_key_pressed(KEY_E)):
		return
	if HIDE_SPOTS.has(pc):
		hiding = true
		hide_t = 0.0
		last_seen = pc
		player.position = _center(pc) - player.size / 2.0
		Sfx.play("click")


func _inside_tick(delta: float) -> void:
	inside_t += delta
	var target := _player_center() + Vector2(-34, 6)
	if inside_t < 0.8:
		lipas_pos = rush_from.lerp(target, inside_t / 0.8)
		lipas_dir = (target - lipas_pos).normalized() if lipas_pos.distance_to(target) > 1.0 else lipas_dir
		skitter_t -= delta
		if skitter_t <= 0.0:
			skitter_t = 0.1
			Sfx.play("skitter", -4.0, 1.2)
	elif inside_t < 2.4 - 0.3 * GameState.upgrade_level("spray"):
		lipas_pos = target + Vector2(sin(inside_t * 30.0) * 2.0, 0)
		spraying = true
		if not spray_sfx:
			spray_sfx = true
			Sfx.play("spray")
	elif not lipas_dead:
		lipas_dead = true
		spraying = false
		Fx.squish(self, 0.3)
		Sfx.play("success", -6.0)
	if lipas_dead and not shower_on and inside_t > 3.6 - 0.3 * GameState.upgrade_level("spray"):
		shower_on = true
		avatar.set_showering(true)
		Sfx.loop("water_loop")


func _on_finished(score: float) -> void:
	Sfx.stop_loop("water_loop")
	var calm := 1.0 - 0.35 * clampf(scare / 12.0, 0.0, 1.0)
	GameState.finish_station(station_id, clampf(score * calm, 0.0, 1.0))


func _paint_world(o: Overlay) -> void:
	var cols: int = MAP[0].length()
	for y in MAP.size():
		for x in cols:
			var cell := Vector2i(x, y)
			var r := Rect2(ORIGIN + Vector2(x, y) * T, Vector2(T, T))
			if walls.has(cell):
				o.draw_rect(r, Color(0.09, 0.03, 0.17, 0.97))
				o.draw_rect(r.grow(-3), Color(0.16, 0.06, 0.27, 0.97))
				for k in DIRS.size():
					var n: Vector2i = cell + DIRS[k]
					if walls.has(n):
						continue
					var col := Color(1.0, 0.25, 0.62) if k < 2 else Color(0.3, 0.85, 1.0)
					var a := r.position
					var b := r.position
					match k:
						0:
							a = r.position + Vector2(T, 0)
							b = r.position + Vector2(T, T)
						1:
							a = r.position
							b = r.position + Vector2(0, T)
						2:
							a = r.position + Vector2(0, T)
							b = r.position + Vector2(T, T)
						3:
							a = r.position
							b = r.position + Vector2(T, 0)
					o.draw_line(a, b, Color(col.r, col.g, col.b, 0.35), 5.0)
					o.draw_line(a, b, col, 2.0)
			else:
				var shade := 0.0 if (x + y) % 2 == 0 else 0.05
				o.draw_rect(r, Color(0.2 + shade, 0.12 + shade, 0.3 + shade, 0.9))
				o.draw_rect(r, Color(0, 0, 0, 0.25), false, 1.0)
	var er := Rect2(ORIGIN + Vector2(exit_cell) * T, Vector2(T, T))
	var pulse := 0.5 + 0.5 * sin(scene_t * 4.0)
	o.draw_circle(er.get_center(), 24.0 + pulse * 4.0, Color(0.3, 1.0, 0.5, 0.18))
	o.draw_rect(er.grow(-2), Color(0.12, 0.55, 0.3))
	var swing := clampf(inside_t / 0.4, 0.0, 1.0) if inside else 0.0
	o.draw_rect(Rect2(er.position.x + 5, er.position.y + 4, T - 10 - 8 * swing, T - 6), Color(0.35, 0.85, 0.95))
	o.draw_rect(Rect2(er.position.x + 5, er.position.y + 4, T - 10 - 8 * swing, T - 6), Ui.INK, false, 2.0)
	Ui.text(o, Vector2(er.position.x - 22, er.position.y - 6), "TANDAS", 12, Color(0.6, 1.0, 0.7), 4)


func _paint_fog(o: Overlay) -> void:
	var pc := _player_center()
	var radius := (170.0 - 70.0 * near_lipas) * fog_flicker
	var cols: int = MAP[0].length()
	for y in MAP.size():
		for x in cols:
			var c := ORIGIN + (Vector2(x, y) + Vector2(0.5, 0.5)) * T
			var a := clampf((c.distance_to(pc) - radius * 0.45) / (radius * 0.9), 0.0, 0.93)
			if a > 0.01:
				o.draw_rect(Rect2(ORIGIN + Vector2(x, y) * T, Vector2(T, T)), Color(0.01, 0.0, 0.03, a))
	if near_lipas > 0.05:
		var pulse := 0.5 + 0.5 * sin(scene_t * 9.0)
		var e := near_lipas * (0.25 + 0.2 * pulse)
		o.draw_rect(Rect2(ORIGIN, Vector2(T * cols, T * MAP.size())), Color(0.8, 0.0, 0.15, e * 0.5))


func _draw_lipas(o: Overlay, pos: Vector2, alpha: float) -> void:
	var flip := clampf((inside_t - 2.0) / 0.3, 0.0, 1.0) if inside else 0.0
	var ang := lipas_dir.angle()
	var wig := scene_t * (26.0 if not lipas_dead else 0.0)
	if inside and inside_t >= 2.0 and not lipas_dead:
		wig = scene_t * 45.0
	o.draw_set_transform(pos, ang + (PI * 0.5 if flip > 0.0 else 0.0), Vector2(1.0, 1.0 - 0.0 * flip))
	var body := Color(0.42, 0.2, 0.08, alpha)
	var belly := Color(0.75, 0.55, 0.25, alpha)
	var ink := Color(0.08, 0.03, 0.02, alpha)
	var legcol := Color(0.25, 0.1, 0.04, alpha)
	var amp := 3.0 if flip > 0.0 else 4.0
	for i in 3:
		var lx := -4.0 + i * 6.0
		var w := sin(wig + i * 2.0) * amp
		var side := 1.0 if flip == 0.0 else 1.0
		o.draw_line(Vector2(lx, 7), Vector2(lx + w, 15 + (2.0 if flip > 0.5 else 0.0)), legcol, 1.6)
		o.draw_line(Vector2(lx, -7), Vector2(lx - w, -15 - (2.0 if flip > 0.5 else 0.0)), legcol, 1.6)
	var pts := PackedVector2Array()
	for k in 20:
		var a := TAU * k / 20.0
		pts.append(Vector2(cos(a) * 15.0, sin(a) * 9.0))
	o.draw_colored_polygon(pts, belly if flip > 0.5 else body)
	o.draw_polyline(pts + PackedVector2Array([pts[0]]), ink, 1.5)
	o.draw_line(Vector2(-12, 0), Vector2(12, 0), ink if flip < 0.5 else legcol, 1.2)
	o.draw_circle(Vector2(15, 0), 5.0, ink)
	o.draw_line(Vector2(18, -2), Vector2(27, -8 + sin(wig * 0.5) * 3.0), legcol, 1.2)
	o.draw_line(Vector2(18, 2), Vector2(27, 8 - sin(wig * 0.5) * 3.0), legcol, 1.2)
	if flip < 0.5:
		o.draw_circle(Vector2(-3, -4), 2.5, Color(1, 0.85, 0.6, alpha * 0.5))
		o.draw_circle(Vector2(17, -2), 1.2, Color(1.0, 0.2, 0.2, alpha) if near_lipas > 0.4 else Color(1, 1, 1, alpha))
	o.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_spray(o: Overlay, pc: Vector2) -> void:
	var cp := pc + Vector2(-8, -2)
	o.draw_rect(Rect2(cp.x - 5, cp.y - 12, 10, 16), Color(0.85, 0.15, 0.2))
	o.draw_rect(Rect2(cp.x - 5, cp.y - 12, 10, 16), Ui.INK, false, 1.5)
	o.draw_rect(Rect2(cp.x - 3, cp.y - 16, 6, 4), Color(0.9, 0.9, 0.95))
	o.draw_rect(Rect2(cp.x - 5, cp.y - 8, 10, 5), Color(0.95, 0.95, 0.95))
	if spraying:
		var k := (inside_t - 0.8) / 1.6
		for i in 16:
			var f := fmod(scene_t * 2.4 + i * 0.137, 1.0)
			var p := cp + Vector2(-6, -14) + Vector2(-26.0 * f - 4.0, 6.0 * f * f) + Vector2(sin(i * 7.1) * 6.0 * f, cos(i * 3.3) * 7.0 * f)
			o.draw_circle(p, 3.0 + 9.0 * f, Color(1, 1, 1, 0.55 * (1.0 - f)))
		o.draw_circle(lipas_pos, 20.0 + sin(scene_t * 9.0) * 3.0, Color(0.9, 1.0, 0.9, 0.22 * sin(k * PI)))
	elif lipas_dead and inside_t < 3.4:
		o.draw_circle(lipas_pos, 24.0, Color(0.9, 1.0, 0.9, 0.2 * (3.4 - inside_t)))


func _paint_top(o: Overlay) -> void:
	var pc := _player_center()
	var asleep := elapsed <= lipas_delay and not inside
	if not inside:
		for hs in HIDE_SPOTS:
			var hc := _center(hs)
			var ready := hide_cd <= 0.0
			var hcol := Color(0.3, 1.0, 0.6, 0.55) if ready else Color(0.5, 0.5, 0.6, 0.3)
			o.draw_rect(Rect2(hc - Vector2(9, 9), Vector2(18, 18)), Color(hcol.r, hcol.g, hcol.b, 0.18))
			o.draw_rect(Rect2(hc - Vector2(9, 9), Vector2(18, 18)), hcol, false, 2.0)
		if hiding:
			Ui.text(o, Vector2(32, 448), Loc.t("Sembunyi... lipas cari tempat kau tadi (%d)") % ceili(HIDE_MAX - hide_t), 14, Color(0.5, 1.0, 0.7), 3)
		elif hide_cd > 0.0:
			Ui.text(o, Vector2(32, 448), Loc.t("Tempat sembunyi sedia dalam %d") % ceili(hide_cd), 13, Color(0.7, 0.7, 0.8), 3)
		else:
			Ui.text(o, Vector2(32, 448), "Kotak hijau: tekan H / E untuk sembunyi", 13, Color(0.5, 1.0, 0.7), 3)
	if near_lipas > 0.05 and not lipas_dead:
		o.draw_circle(lipas_pos, 30.0 + near_lipas * 14.0, Color(1.0, 0.1, 0.3, 0.1 + 0.2 * near_lipas))
	var vis := clampf(1.0 - (lipas_pos.distance_to(pc) - 60.0) / 220.0, 0.35, 1.0)
	_draw_lipas(o, lipas_pos, vis * (0.5 if asleep else 1.0))
	if inside:
		_draw_spray(o, pc)

	Ui.text(o, Vector2(656 + 144 - Ui.text_width("PETA", 22) / 2.0, 42), "PETA", 22, Ui.ORANGE, 5)
	var mc := 11.0
	var mo := Vector2(672.0 + (256.0 - mc * MAP[0].length()) / 2.0, 56.0)
	var cols: int = MAP[0].length()
	for y in MAP.size():
		for x in cols:
			var cell := Vector2i(x, y)
			var r := Rect2(mo + Vector2(x, y) * mc, Vector2(mc, mc))
			if walls.has(cell):
				o.draw_rect(r, Color(0.3, 0.12, 0.45))
			else:
				o.draw_rect(r, Color(0.07, 0.03, 0.12))
	var mer := Rect2(mo + Vector2(exit_cell) * mc, Vector2(mc, mc))
	o.draw_rect(mer, Color(0.3, 1.0, 0.5))
	var pm := mo + (Vector2(_cell(pc)) + Vector2(0.5, 0.5)) * mc
	o.draw_circle(pm, 4.0, Ui.INK)
	o.draw_circle(pm, 3.0, Ui.ORANGE)
	var gsteps: int = 99
	if elapsed > lipas_delay:
		gsteps = _bfs(_cell(pc)).get(_cell(lipas_pos), 99)
	if gsteps <= 9 and not inside:
		var gm := mo + (Vector2(_cell(lipas_pos)) + Vector2(0.5, 0.5)) * mc
		o.draw_circle(gm, 4.0 + 1.5 * sin(scene_t * 10.0), Color(1.0, 0.25, 0.35))

	var py := 56.0 + mc * MAP.size() + 22.0
	var pcell := _cell(pc)
	var steps: int = exit_dist.get(pcell, 0)
	Ui.text(o, Vector2(672, py), "KE TANDAS", 13, Ui.ORANGE, 4)
	if not inside:
		var dir := Vector2.ZERO
		var bd := steps
		for d in DIRS:
			var n: Vector2i = pcell + d
			if exit_dist.has(n) and exit_dist[n] < bd:
				bd = exit_dist[n]
				dir = Vector2(d)
		var ac := Vector2(760, py + 34)
		if dir != Vector2.ZERO:
			var perp := Vector2(-dir.y, dir.x)
			o.draw_circle(ac, 22.0, Ui.INK)
			o.draw_circle(ac, 19.0, Color(0.1, 0.3, 0.18))
			o.draw_colored_polygon(PackedVector2Array([ac + dir * 15.0, ac - dir * 8.0 + perp * 10.0, ac - dir * 3.0, ac - dir * 8.0 - perp * 10.0]), Color(0.45, 1.0, 0.6))
		Ui.text(o, Vector2(796, py + 40), Loc.t("%d langkah") % steps, 15, Color.WHITE, 3)
	else:
		Ui.text(o, Vector2(672, py + 38), "Pintu dikunci!", 15, Ui.GREEN, 3)

	var dy := py + 70.0
	Ui.text(o, Vector2(672, dy), "BAHAYA LIPAS", 13, Ui.ORANGE, 4)
	o.draw_style_box(Ui.box(Color(0.03, 0.0, 0.07), Color(0.4, 0.2, 0.5), 5, 2), Rect2(672, dy + 8, 256, 20))
	if near_lipas > 0.01:
		o.draw_rect(Rect2(675, dy + 11, 250.0 * near_lipas, 14), Color(1.0, 0.25, 0.35))
	if inside:
		o.draw_style_box(Ui.box(Color(0.06, 0.02, 0.12, 0.92), Ui.GREEN, 10, 2), Rect2(20, 454, 616, 36))
		var msg := "Pintu dikunci... ambil spray!"
		if inside_t >= 0.8 and not lipas_dead:
			msg = "PSSSHHH! Lipas mati!"
		elif lipas_dead and not shower_on:
			msg = "Lipas dah mati. Fuh."
		elif shower_on:
			msg = "Tahan SPACE untuk mandi!"
		Ui.text(o, Vector2(32, 478), msg, 15, Color.WHITE, 3)
		if shower_on:
			for i in PARTS.size():
				o.draw_rect(Rect2(440.0 + i * 48.0, 466, 42, 12), Color(0.03, 0, 0.07))
				o.draw_rect(Rect2(440.0 + i * 48.0, 466, 42.0 * progress[i], 12), Ui.GREEN if progress[i] >= 1.0 else Ui.WATER)
	elif elapsed <= lipas_delay:
		Ui.text(o, Vector2(32, 472), Loc.t("Lipas bangun dalam %d...  Lari!") % ceili(lipas_delay - elapsed), 15, Color(1.0, 0.7, 0.8), 3)
	else:
		Ui.text(o, Vector2(32, 472), "WASD = lari.  Jangan kena lipas. Cari pintu TANDAS (hijau).", 14, Color(0.9, 0.85, 1.0), 3)


func _exit_tree() -> void:
	Sfx.stop_loop("water_loop")
