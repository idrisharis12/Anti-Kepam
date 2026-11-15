extends Node

const STATIONS := ["rnr", "gas", "lrt", "mall"]
const NAMES := {"rnr": "R&R", "gas": "Gas Station", "lrt": "LRT", "mall": "Shopping Mall"}
const LOSE_TEXT := {
	"viral": "Hantu tangkap kau di mall. Videonya tersebar: kau viral di Berita Kepam 26!",
	"spread": "Kepam dah merebak... SATU NEGERI KEPAM! Berita Kepam 26: negeri lumpuh.",
	"gf": "Terlalu lambat. GF dah kahwin dengan lelaki other.",
	"lake": "Tasik masih malap. Kau masih kepam. GF tak balik.",
}
const GF_TIME := 420.0

var step := 0
var scores := {}
var soap := 0
var tissue := 0
var kuman := 0
var spread := 0.0
var gf_left := GF_TIME
var running := false
var over := false
var lose_reason := ""
var intro_seen := false
var won := false


func reset() -> void:
	step = 0
	scores = {}
	soap = 0
	tissue = 0
	kuman = 0
	spread = 0.0
	gf_left = GF_TIME
	running = false
	over = false
	lose_reason = ""
	won = false


func _process(delta: float) -> void:
	if not running or over:
		return
	gf_left -= delta
	if gf_left <= 0.0:
		lose("gf")


func lose(reason: String) -> void:
	if over:
		return
	over = true
	running = false
	lose_reason = reason
	get_tree().change_scene_to_file("res://scenes/ending.tscn")


func add_spread(amount: float) -> void:
	spread = clampf(spread + amount, 0.0, 100.0)
	if spread >= 100.0:
		lose("spread")


func finish_station(id: String, score: float) -> void:
	scores[id] = clampf(score, 0.0, 1.0)
	step += 1
	add_spread((1.0 - scores[id]) * 40.0)
	if not over:
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func average_score() -> float:
	var total := 0.0
	for id in STATIONS:
		total += scores.get(id, 0.0)
	return total / STATIONS.size()


func hud_text() -> String:
	var t := int(maxf(gf_left, 0.0))
	return "Kepam negeri: %d%%   |   GF kahwin lelaki lain: %d:%02d   |   Kuman %d  Sabun %d  Tisu %d" % [
		int(spread), floori(t / 60.0), t % 60, kuman, soap, tissue]


func move_vec() -> Vector2:
	var v := Vector2.ZERO
	if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A):
		v.x -= 1
	if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D):
		v.x += 1
	if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W):
		v.y -= 1
	if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S):
		v.y += 1
	return v.normalized()


func make_label(parent: Node, text: String, pos: Vector2, size := 20) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	parent.add_child(l)
	return l
