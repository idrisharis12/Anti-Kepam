class_name ShowerBase
extends Node2D
# Shared shower: wash 4 body parts by holding SPACE. Stations add their own twist on top.

const PARTS := ["Kepala", "Ketiak", "Belakang", "Kaki"]
const WASH_RATE := 0.13

var station_id := ""
var progress := [0.0, 0.0, 0.0, 0.0]
var current := 0
var time_limit := 60.0
var time_left := 60.0
var elapsed := 0.0
var wash_mult := 1.0
var active := true
var done := false
var bg: ColorRect
var title: Label
var status: Label
var body: Label
var hud: Label


func _ready() -> void:
	Sfx.stop_all_loops()
	Sfx.play_music("station")
	bg = ColorRect.new()
	bg.size = Vector2(960, 540)
	add_child(bg)
	title = GameState.make_label(self, "", Vector2(40, 12), 22)
	status = GameState.make_label(self, "", Vector2(40, 48), 18)
	body = GameState.make_label(self, "", Vector2(660, 90), 18)
	hud = GameState.make_label(self, "", Vector2(20, 508), 15)
	hud.visible = false
	add_child(Hud.new())
	_build()
	time_left = time_limit


func _build() -> void:
	pass


func _tick(_delta: float) -> void:
	pass


func add_backdrop(path: String) -> TextureRect:
	var img := TextureRect.new()
	img.texture = load(path)
	img.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	img.size = Vector2(540, 540)
	add_child(img)
	move_child(img, 1)
	for lab in [title, status, body]:
		lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lab.custom_minimum_size.x = 380
	title.position = Vector2(555, 14)
	status.position = Vector2(555, 110)
	body.position = Vector2(555, 250)
	return img


func can_wash() -> bool:
	return true


func _process(delta: float) -> void:
	if done:
		return
	elapsed += delta
	_tick(delta)
	if done:
		return
	if active:
		if time_limit > 0.0:
			time_left -= delta
			if time_left <= 0.0:
				_finish()
				return
		if Input.is_key_pressed(KEY_SPACE) and can_wash():
			_wash(delta)
	_refresh()


func _wash(delta: float) -> void:
	var rate := WASH_RATE * wash_mult * (1.5 if GameState.soap > 0 else 1.0) * (1.0 + 0.2 * GameState.upgrade_level("shower"))
	progress[current] = minf(1.0, progress[current] + delta * rate)
	if progress[current] >= 1.0:
		_advance()


func _advance() -> void:
	for i in PARTS.size():
		if progress[i] < 1.0:
			current = i
			return
	_finish()


func _finish() -> void:
	if done:
		return
	done = true
	var clean := 0.0
	for p in progress:
		clean += p
	clean /= PARTS.size()
	var speed := clampf(time_left / time_limit, 0.0, 1.0) if time_limit > 0.0 else clampf(1.0 - elapsed / 120.0, 0.0, 1.0)
	var score := clean * (0.75 + 0.25 * speed)
	if GameState.tissue > 0:
		GameState.tissue -= 1
		score += 0.1
	_on_finished(clampf(score, 0.0, 1.0))


func _on_finished(score: float) -> void:
	GameState.finish_station(station_id, score)


func _refresh() -> void:
	var s := ""
	for i in PARTS.size():
		var mark := ">" if (i == current and active) else "  "
		s += "%s %s %s\n" % [mark, Loc.t(PARTS[i]), bar(progress[i])]
	if time_limit > 0.0 and active:
		s += Loc.t("\nMasa: %d") % ceili(maxf(time_left, 0.0))
	body.text = s
	hud.text = GameState.hud_text()


func bar(v: float) -> String:
	var n := int(clampf(v, 0.0, 1.0) * 10)
	return "[" + "#".repeat(n) + "-".repeat(10 - n) + "]"
