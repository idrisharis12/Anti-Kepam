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
var difficulty := 1
var streak := 0
var kuman_at_start := 0
var upgrades := {"mop": 0, "spray": 0, "shower": 0}
var best_scores := {}
var replay_id := ""

const UPGRADE_COST := {"mop": 4, "spray": 3, "shower": 5}
const UPGRADE_MAX := {"mop": 2, "spray": 3, "shower": 2}


func reset() -> void:
	step = 0
	scores = {}
	soap = 0
	tissue = 0
	kuman = 0
	spread = 0.0
	gf_left = GF_TIME * Difficulty.timer_mult()
	streak = 0
	kuman_at_start = 0
	replay_id = ""
	upgrades = {"mop": 0, "spray": 0, "shower": 0}
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


func start_station() -> void:
	kuman_at_start = kuman


func upgrade_level(id: String) -> int:
	return int(upgrades.get(id, 0))


func buy_upgrade(id: String) -> bool:
	var lv := upgrade_level(id)
	if lv >= int(UPGRADE_MAX[id]) or kuman < int(UPGRADE_COST[id]):
		return false
	kuman -= int(UPGRADE_COST[id])
	upgrades[id] = lv + 1
	return true


func finish_station(id: String, score: float) -> void:
	score = clampf(score, 0.0, 1.0)
	if replay_id != "":
		replay_id = ""
		best_scores[id] = maxf(float(best_scores.get(id, 0.0)), score)
		get_tree().change_scene_to_file("res://scenes/station_select.tscn")
		return
	if kuman >= kuman_at_start:
		streak += 1
		if streak >= 2:
			score = minf(1.0, score + 0.03 * minf(streak - 1, 3))
	else:
		streak = 0
	Sfx.stinger()
	scores[id] = score
	best_scores[id] = maxf(float(best_scores.get(id, 0.0)), score)
	step += 1
	add_spread((1.0 - scores[id]) * 40.0 * Difficulty.spread_mult())
	if not over:
		get_tree().change_scene_to_file("res://scenes/main.tscn")


func average_score() -> float:
	var total := 0.0
	for id in STATIONS:
		total += scores.get(id, 0.0)
	return total / STATIONS.size()


func hud_text() -> String:
	var t := int(maxf(gf_left, 0.0))
	return Loc.t("Kepam negeri: %d%%   |   GF kahwin lelaki lain: %d:%02d   |   Kuman %d  Sabun %d  Tisu %d") % [
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
