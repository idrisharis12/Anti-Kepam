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
	title.text = "Shopping Mall  -  Hantu kejar! Lari ke titik mandi 1-4."
	status.position = Vector2(40, 44)
	status.text = "WASD gerak.  Berdiri di titik dan tahan SPACE untuk mandi.  Jangan kena hantu!"
	var start := Vector2.ZERO
	for y in MAP.size():
		for x in MAP[y].length():
			var c: String = MAP[y][x]
			var px := ORIGIN + Vector2(x, y) * T
			if c == "#":
				walls[Vector2i(x, y)] = true
				_rect(px, Vector2(T, T), Color(0.12, 0.05, 0.2, 0.82))
			elif c == "S":
				start = px + Vector2(5, 5)
			elif c.is_valid_int():
				var idx := int(c) - 1
				points[idx] = Vector2i(x, y)
				point_rects[idx] = _rect(px, Vector2(T, T), Color(0.2, 0.5, 0.9))
				GameState.make_label(self, c, px + Vector2(8, 2), 18)
	player.color = Color(0.3, 0.55, 0.3)
	player.size = Vector2(18, 18)
	player.position = start
	add_child(player)
	ghost.color = Color(0.9, 0.9, 1.0, 0.85)
	ghost.size = Vector2(20, 20)
	ghost.position = ORIGIN + Vector2(11, 9) * T + Vector2(4, 4)
	add_child(ghost)


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
	for i in points:
		point_rects[i].color = Color(0.2, 0.5, 0.9).lerp(Color(0.3, 0.9, 0.4), progress[i])
