extends ShowerBase
# Shopping mall: a ghost chases the boy through a maze. Run between shower points (1-4)
# and hold SPACE on each to wash that body part. Standing still while washing. Caught = viral.

const T := 28
const ORIGIN := Vector2(20, 84)
const MAP := [
	"######################",
	"#S...#...1...#.......#",
	"#.##.#.#####.#.#####.#",
	"#.#..#.#...#...#...#.#",
	"#.#.##.#.#.#####.#.#.#",
	"#.#....#.#...2...#...#",
	"#.######.#######.#####",
	"#........#.....#..3..#",
	"#.######.#.###.#.###.#",
	"#.#....#...#.....#...#",
	"#.#.##.#####.#####.#.#",
	"#...#........#.....#4#",
	"######################",
]

var walls := {}
var points := {}
var point_rects := {}
var player := ColorRect.new()
var ghost := ColorRect.new()
var ghost_delay := 3.0
var avatar := AvatarView.new()
var near_ghost := 0.0
var scene_t := 0.0


func _build() -> void:
	station_id = "mall"
	Sfx.play_music("mall")
	Sfx.play("ghost")
	time_limit = 0.0
	bg.color = Color(0.08, 0.03, 0.1)
	var tex := AtlasTexture.new()
	tex.atlas = load("res://assets/mall_bg.png")
	tex.region = Rect2(0, 150, 1024, 710)
	var img := TextureRect.new()
	img.texture = tex
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.size = Vector2(960, 540)
	img.modulate = Color(0.55, 0.55, 0.65)
	add_child(img)
	move_child(img, 1)
	title.visible = false
	status.visible = false
	body.visible = false
	var head := Ui.label(self, "SHOPPING MALL", Vector2(20, 12), 30, Ui.ORANGE, 616)
	head.add_theme_constant_override("outline_size", 8)
	Ui.label(self, "Hantu kejar! Lari ke titik mandi 1-4", Vector2(20, 54), 14, Ui.PINK, 616)
	var side := Ui.panel(self, Rect2(656, 10, 288, 474), Ui.PINK)
	move_child(side, 2)
	Ui.label(self, "CARA", Vector2(656, 18), 22, Ui.ORANGE, 288)
	Ui.rule(self, Vector2(672, 52), 256, Ui.PINK)
	var how := Ui.label(self, "WASD = lari\nBerdiri di titik biru, tahan SPACE untuk mandi\nJangan kena hantu!", Vector2(672, 62), 14, Color.WHITE, 256, false)
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.custom_minimum_size.x = 256
	var ov := Overlay.new()
	ov.painter = _paint
	ov.z_index = 3
	add_child(ov)
	var start := Vector2.ZERO
	for y in MAP.size():
		for x in MAP[y].length():
			var c: String = MAP[y][x]
			var px := ORIGIN + Vector2(x, y) * T
			if c == "#":
				walls[Vector2i(x, y)] = true
				pass
			elif c == "S":
				start = px + Vector2(5, 5)
			elif c.is_valid_int():
				var idx := int(c) - 1
				points[idx] = Vector2i(x, y)
				point_rects[idx] = px
	player.color = Color(0, 0, 0, 0)
	player.size = Vector2(18, 18)
	player.position = start
	add_child(player)
	ghost.color = Color(0, 0, 0, 0)
	ghost.size = Vector2(20, 20)
	ghost.position = ORIGIN + Vector2(11, 9) * T + Vector2(4, 4)
	add_child(ghost)
	avatar.scale = Vector2(0.45, 0.45)
	avatar.z_index = 4
	avatar.dirt = 0.5
	add_child(avatar)


func _rect(pos: Vector2, size: Vector2, color: Color) -> ColorRect:
	var r := ColorRect.new()
	r.position = pos
	r.size = size
	r.color = color
	add_child(r)
	return r


func _cell(p: Vector2) -> Vector2i:
	return Vector2i(((p - ORIGIN) / T).floor())


func _blocked(p: Vector2, s: Vector2) -> bool:
	for corner in [p, p + Vector2(s.x, 0), p + Vector2(0, s.y), p + s]:
		if walls.has(_cell(corner)):
			return true
	return false


func _move(node: ColorRect, dir: Vector2, speed: float, delta: float) -> void:
	var step := dir * speed * delta
	var nx := node.position + Vector2(step.x, 0)
	if not _blocked(nx, node.size):
		node.position = nx
	var ny := node.position + Vector2(0, step.y)
	if not _blocked(ny, node.size):
		node.position = ny


func can_wash() -> bool:
	var c := _cell(player.position + player.size / 2)
	for i in points:
		if points[i] == c and progress[i] < 1.0:
			current = i
			return true
	return false


func _tick(delta: float) -> void:
	if not (Input.is_key_pressed(KEY_SPACE) and can_wash()):
		_move(player, GameState.move_vec(), 110.0, delta)
	if elapsed > ghost_delay:
		var d := player.position - ghost.position
		_move(ghost, d.normalized(), 68.0, delta)
		if d.length() < 18.0:
			done = true
			Sfx.play("fail")
			GameState.lose("viral")
			return
	scene_t += delta
	avatar.position = player.position + Vector2(9, 22)
	var washing := Input.is_key_pressed(KEY_SPACE) and can_wash()
	var mean := 0.0
	for p in progress:
		mean += p
	avatar.dirt = clampf(0.55 - mean / PARTS.size() * 0.55, 0.0, 1.0)
	near_ghost = clampf(1.0 - (player.position - ghost.position).length() / 220.0, 0.0, 1.0) if elapsed > ghost_delay else 0.0
	if washing:
		avatar.position.y += sin(scene_t * 30.0) * 1.2


func _paint(o: Overlay) -> void:
	for y in MAP.size():
		for x in MAP[y].length():
			if MAP[y][x] != "#":
				continue
			var r := Rect2(ORIGIN + Vector2(x, y) * T, Vector2(T, T))
			o.draw_rect(r, Color(0.1, 0.03, 0.2, 0.9))
			o.draw_rect(r.grow(-1), Color(0.18, 0.06, 0.3, 0.9))
			o.draw_rect(Rect2(r.position, Vector2(T, 3)), Color(1.0, 0.25, 0.6, 0.6))
	for i in points:
		var px: Vector2 = point_rects[i]
		var c := px + Vector2(T, T) / 2.0
		var pr: float = progress[i]
		var col := Color(0.25, 0.65, 1.0).lerp(Color(0.3, 0.95, 0.4), pr)
		var pulse := 0.5 + 0.5 * sin(scene_t * 4.0 + i)
		o.draw_circle(c, 13.0 + pulse * 2.0, Color(col.r, col.g, col.b, 0.3))
		o.draw_circle(c, 11.0, Ui.INK)
		o.draw_circle(c, 9.5, col.darkened(0.2))
		if pr >= 1.0:
			o.draw_line(c + Vector2(-4, 0), c + Vector2(-1, 4), Color.WHITE, 2.5)
			o.draw_line(c + Vector2(-1, 4), c + Vector2(5, -4), Color.WHITE, 2.5)
		else:
			Ui.text(o, c + Vector2(-4, 5), str(i + 1), 14, Color.WHITE, 3)
			if pr > 0.01:
				o.draw_arc(c, 13.0, -PI / 2, -PI / 2 + TAU * pr, 24, Color.WHITE, 3.0)
	var g := ghost.position + ghost.size / 2.0
	var bob := sin(scene_t * 5.0) * 3.0
	var gc := Vector2(g.x, g.y + bob)
	if near_ghost > 0.05:
		o.draw_circle(gc, 34.0 + near_ghost * 14.0, Color(1.0, 0.1, 0.3, 0.12 + 0.2 * near_ghost))
	o.draw_circle(gc, 17.0, Color(0.95, 0.95, 1.0, 0.88))
	o.draw_rect(Rect2(gc.x - 17.0, gc.y, 34.0, 14.0), Color(0.95, 0.95, 1.0, 0.88))
	for k in 4:
		o.draw_circle(Vector2(gc.x - 12.75 + k * 8.5, gc.y + 14.0 + sin(scene_t * 8.0 + k) * 2.0), 4.5, Color(0.95, 0.95, 1.0, 0.88))
	o.draw_circle(gc + Vector2(-6, -3), 3.5, Ui.INK)
	o.draw_circle(gc + Vector2(6, -3), 3.5, Ui.INK)
	o.draw_circle(gc + Vector2(-6, -3), 1.2, Color(1.0, 0.2, 0.3) if near_ghost > 0.4 else Color.WHITE)
	o.draw_circle(gc + Vector2(6, -3), 1.2, Color(1.0, 0.2, 0.3) if near_ghost > 0.4 else Color.WHITE)
	o.draw_circle(gc + Vector2(0, 7), 3.0 + near_ghost * 2.0, Ui.INK)
	for i in PARTS.size():
		var y := 178.0 + i * 36.0
		Ui.text(o, Vector2(672, y + 14), "%d  %s" % [i + 1, PARTS[i]], 14, Ui.GREEN if progress[i] >= 1.0 else Color.WHITE, 3)
		o.draw_style_box(Ui.box(Color(0.03, 0.0, 0.07), Color(0.4, 0.2, 0.5), 5, 2), Rect2(780, y, 148, 20))
		var w := 142.0 * clampf(progress[i], 0.0, 1.0)
		if w > 1.0:
			o.draw_rect(Rect2(783, y + 3, w, 14), Ui.GREEN if progress[i] >= 1.0 else Ui.WATER)
	Ui.text(o, Vector2(672, 350), "BAHAYA HANTU", 13, Ui.ORANGE, 4)
	o.draw_style_box(Ui.box(Color(0.03, 0.0, 0.07), Color(0.4, 0.2, 0.5), 5, 2), Rect2(672, 360, 256, 22))
	if near_ghost > 0.01:
		o.draw_rect(Rect2(675, 363, 250.0 * near_ghost, 16), Color(1.0, 0.25, 0.35))
	if elapsed <= ghost_delay:
		Ui.text(o, Vector2(672, 412), "Hantu bangun dalam %d..." % ceili(ghost_delay - elapsed), 14, Color(1.0, 0.7, 0.8), 3)
