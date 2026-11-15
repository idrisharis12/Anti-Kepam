extends Node2D

const MAP_SIZE := 540.0
const ZONES := {
	"rnr": Vector2(142, 132),
	"gas": Vector2(320, 100),
	"lrt": Vector2(406, 343),
	"mall": Vector2(105, 448),
}
const LAKE := Vector2(485, 237)
const BONUS := Vector2(264, 263)
const RADIUS := 34.0
const SOAP_COST := 3
const TISSUE_COST := 2

var player: Node2D
var hint: Label
var msg: Label
var soap_pos := Vector2(214, 285)
var tissue_pos := Vector2(314, 285)
var scene_t := 0.0
var buy_lock := false
var flash_msg := 0.0


func _ready() -> void:
	if not GameState.intro_seen:
		set_process(false)
		get_tree().change_scene_to_file.call_deferred("res://scenes/intro.tscn")
		return
	var floor_rect := ColorRect.new()
	floor_rect.color = Color(0.1, 0.03, 0.12)
	floor_rect.size = Vector2(960, 540)
	add_child(floor_rect)

	var map := TextureRect.new()
	map.texture = load("res://assets/hub_bg.png")
	map.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	map.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	map.size = Vector2(MAP_SIZE, MAP_SIZE)
	add_child(map)

	var marks := Overlay.new()
	marks.painter = _paint_map
	add_child(marks)

	player = preload("res://scripts/player.gd").new()
	player.position = BONUS + Vector2(0, 90)
	player.bounds = Rect2(24, 40, MAP_SIZE - 48, MAP_SIZE - 70)
	add_child(player)

	Ui.panel(self, Rect2(556, 10, 388, 474), Ui.PINK)
	var t1 := Ui.label(self, "ANTI-KEPAM", Vector2(556, 16), 34, Ui.ORANGE, 388)
	t1.add_theme_constant_override("outline_size", 9)
	Ui.label(self, "Mandi dulu, baru boleh pujuk GF", Vector2(556, 62), 14, Ui.PINK, 388)
	Ui.rule(self, Vector2(574, 88), 352, Ui.PINK)
	Ui.label(self, "MISI SEKARANG", Vector2(574, 96), 13, Ui.WATER, 352, false)
	hint = Ui.label(self, "", Vector2(574, 116), 20, Color.WHITE, 352, false)
	Ui.rule(self, Vector2(574, 160), 352, Color(0.4, 0.15, 0.5))
	var list := Overlay.new()
	list.painter = _paint_list
	add_child(list)
	msg = Ui.label(self, "", Vector2(574, 424), 14, Ui.ORANGE, 352, false)

	var hud := Hud.new()
	add_child(hud)

	GameState.running = true
	Sfx.stop_all_loops()
	Sfx.play_music("hub")


func _zone_state(id: String) -> int:
	var idx: int = GameState.STATIONS.find(id)
	if idx < GameState.step:
		return 2
	return 1 if idx == GameState.step else 0


func _ring(o: CanvasItem, c: Vector2, col: Color, active: bool) -> void:
	var p := 0.5 + 0.5 * sin(scene_t * 4.0) if active else 0.0
	o.draw_circle(c, RADIUS, Color(col.r, col.g, col.b, 0.25 + 0.15 * p))
	o.draw_arc(c, RADIUS, 0, TAU, 40, Ui.INK, 6.0, true)
	o.draw_arc(c, RADIUS, 0, TAU, 40, col, 3.5, true)
	if active:
		o.draw_arc(c, RADIUS + 4 + p * 8, 0, TAU, 40, Color(col.r, col.g, col.b, 0.8 - p * 0.6), 2.5, true)


func _pill(o: CanvasItem, c: Vector2, s: String, col: Color) -> void:
	var w := Ui.text_width(s, 13) + 16
	o.draw_style_box(Ui.box(Color(0.08, 0.015, 0.14, 0.92), col, 9, 2), Rect2(c.x - w / 2, c.y - 10, w, 20))
	Ui.text(o, Vector2(c.x - w / 2 + 8, c.y + 5), s, 13, Color.WHITE, 3)


func _paint_map(o: Overlay) -> void:
	for id in ZONES:
		var st := _zone_state(id)
		var col: Color = [Color(0.55, 0.55, 0.7), Ui.ORANGE, Ui.GREEN][st]
		var c: Vector2 = ZONES[id]
		_ring(o, c, col, st == 1)
		var idx: int = GameState.STATIONS.find(id)
		o.draw_circle(c, 14, Ui.INK)
		o.draw_circle(c, 12, col.darkened(0.2))
		if st == 2:
			o.draw_line(c + Vector2(-5, 0), c + Vector2(-1, 5), Color.WHITE, 3.0)
			o.draw_line(c + Vector2(-1, 5), c + Vector2(6, -5), Color.WHITE, 3.0)
		else:
			Ui.text(o, c + Vector2(-5, 6), str(idx + 1), 17, Color.WHITE, 3)
		_pill(o, c + Vector2(0, -(RADIUS + 14) if c.y > 400 else RADIUS + 14), GameState.NAMES[id], col)
	var open: bool = GameState.step >= GameState.STATIONS.size()
	_ring(o, LAKE, Ui.ORANGE if open else Color(0.55, 0.55, 0.7), open)
	_pill(o, LAKE + Vector2(0, RADIUS + 14), "Golden Lake", Ui.ORANGE if open else Color(0.55, 0.55, 0.7))
	_pill(o, BONUS + Vector2(0, -50), "Kedai Hygiene", Ui.WATER)
	var bob := sin(scene_t * 3.0) * 3.0
	for it in [["soap", soap_pos, SOAP_COST], ["tissue", tissue_pos, TISSUE_COST]]:
		var c: Vector2 = it[1] + Vector2(11, 11 + bob)
		o.draw_circle(it[1] + Vector2(11, 28), 12, Color(0, 0, 0, 0.3))
		o.draw_circle(c, 22, Color(1, 1, 1, 0.13 + 0.07 * sin(scene_t * 4.0)))
		if it[0] == "soap":
			Ui.soap(o, c, 1.4)
		else:
			Ui.tissue(o, c, 1.4)
		_pill(o, it[1] + Vector2(11, 46), "%s  %dK" % ["Sabun" if it[0] == "soap" else "Tisu", it[2]], Ui.WATER)


func _paint_list(o: Overlay) -> void:
	Ui.text(o, Vector2(574, 180), "PERJALANAN", 13, Ui.ORANGE, 4)
	var rows := GameState.STATIONS.size() + 1
	for i in rows:
		var y := 190.0 + i * 33.0
		var lake := i == GameState.STATIONS.size()
		var st := 0
		if lake:
			st = 1 if GameState.step >= GameState.STATIONS.size() else 0
		else:
			st = _zone_state(GameState.STATIONS[i])
		var col: Color = [Color(0.5, 0.35, 0.6), Ui.ORANGE, Ui.GREEN][st]
		var label: String = "Golden Lake" if lake else GameState.NAMES[GameState.STATIONS[i]]
		o.draw_style_box(Ui.box(Color(0.17, 0.05, 0.22), col, 8, 2), Rect2(574, y, 352, 28))
		o.draw_circle(Vector2(592, y + 14), 10, col)
		if st == 2:
			o.draw_line(Vector2(587, y + 14), Vector2(591, y + 19), Color.WHITE, 2.5)
			o.draw_line(Vector2(591, y + 19), Vector2(598, y + 9), Color.WHITE, 2.5)
		else:
			Ui.text(o, Vector2(588, y + 19), str(i + 1), 13, Ui.INK, 0)
		Ui.text(o, Vector2(612, y + 19), label, 15, Color.WHITE if st > 0 else Color(0.7, 0.6, 0.75), 3)
		if st == 2 and not lake:
			var sc: float = GameState.scores.get(GameState.STATIONS[i], 0.0)
			Ui.text(o, Vector2(850, y + 19), "%d%%" % int(sc * 100.0), 14, Ui.GREEN, 3)
		elif st == 1:
			Ui.text(o, Vector2(840, y + 19), "SINI >", 13, Ui.ORANGE, 3)
	Ui.text(o, Vector2(574, 396), "KAWALAN", 13, Ui.ORANGE, 4)
	Ui.text(o, Vector2(574, 414), "WASD / Anak panah = jalan      B = beli", 12, Ui.CREAM, 3)


func _set_hint() -> void:
	if GameState.step >= GameState.STATIONS.size():
		hint.text = "Semua siap! Terjun ke Golden Lake."
	else:
		var id: String = GameState.STATIONS[GameState.step]
		hint.text = "Pergi ke %s" % GameState.NAMES[id]


func _process(delta: float) -> void:
	scene_t += delta
	flash_msg = maxf(0.0, flash_msg - delta)
	if flash_msg <= 0.0:
		msg.text = ""
	_set_hint()

	var near_soap := player.position.distance_to(soap_pos + Vector2(11, 11)) < 40
	var near_tissue := player.position.distance_to(tissue_pos + Vector2(11, 11)) < 40
	if near_soap or near_tissue:
		var item := "soap" if near_soap else "tissue"
		var cost: int = SOAP_COST if near_soap else TISSUE_COST
		if flash_msg <= 0.0:
			msg.text = "Kedai Hygiene: tekan B beli %s (%d kuman)" % ["Sabun" if near_soap else "Tisu", cost]
		if Input.is_key_pressed(KEY_B) and not buy_lock:
			buy_lock = true
			flash_msg = 1.5
			if GameState.kuman >= cost:
				GameState.kuman -= cost
				if item == "soap":
					GameState.soap += 1
				else:
					GameState.tissue += 1
				msg.text = "Dibeli! %s +1" % ("Sabun" if item == "soap" else "Tisu")
			else:
				msg.text = "Kuman tak cukup!"
	if not Input.is_key_pressed(KEY_B):
		buy_lock = false

	if scene_t < 0.5:
		return
	for id in ZONES:
		if player.position.distance_to(ZONES[id]) < RADIUS:
			var idx: int = GameState.STATIONS.find(id)
			if idx == GameState.step:
				get_tree().change_scene_to_file("res://scenes/%s.tscn" % id)
				return
			elif idx > GameState.step:
				msg.text = "Belum lagi. Pergi %s dulu." % GameState.NAMES[GameState.STATIONS[GameState.step]]
				flash_msg = 0.3
	if GameState.step >= GameState.STATIONS.size() and player.position.distance_to(LAKE) < RADIUS:
		get_tree().change_scene_to_file("res://scenes/ending.tscn")
