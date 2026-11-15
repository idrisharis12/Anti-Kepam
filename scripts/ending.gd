extends ShowerBase
# Ending: the golden lake is the final, biggest shower. Brightness = 70% average station score + 30% this shower.
# Also shows the lose screens (viral / spread / gf) when GameState.lose_reason is set.

const WIN_BRIGHTNESS := 0.6

var lake: TextureRect
var result: Label
var result_shown := false
var base_avg := 0.0


func _build() -> void:
	station_id = "lake"
	Sfx.stop_all_loops()
	Sfx.play_music("lake_sad" if GameState.lose_reason != "" else "lake")
	time_limit = 30.0
	GameState.running = false
	bg.color = Color(0.05, 0.08, 0.15)
	bg.color = Color(0.1, 0.03, 0.12)
	lake = add_backdrop("res://assets/lake_bg.png")
	lake.modulate = Color(0.3, 0.3, 0.4)
	result = GameState.make_label(self, "", Vector2(555, 250), 20)
	result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result.custom_minimum_size.x = 380
	body.position = Vector2(555, 330)
	if GameState.lose_reason != "":
		active = false
		done = true
		result_shown = true
		title.text = "KALAH"
		result.text = "%s\n\nTekan ENTER untuk tengok pengakhiran." % GameState.LOSE_TEXT[GameState.lose_reason]
		return
	base_avg = GameState.average_score()
	title.text = "Golden Lake  -  Mandi terakhir!"
	status.text = "Terjun! Tahan SPACE untuk mandi penuh. Tasik cerah ikut skor semua mandi tadi."


func _process(delta: float) -> void:
	if result_shown:
		hud.text = GameState.hud_text()
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER):
			set_process(false)
			get_tree().change_scene_to_file("res://scenes/outro.tscn")
		return
	super._process(delta)
	var clean := 0.0
	for p in progress:
		clean += p
	clean /= PARTS.size()
	var b := base_avg * 0.7 + clean * 0.3
	_set_glow(b)


func _set_glow(b: float) -> void:
	var k := clampf(b / 0.9, 0.0, 1.0)
	lake.modulate = Color(0.3, 0.3, 0.4).lerp(Color(1.15, 1.05, 0.9), k)


func _on_finished(score: float) -> void:
	var brightness := base_avg * 0.7 + score * 0.3
	_set_glow(brightness)
	result_shown = true
	if brightness >= WIN_BRIGHTNESS:
		GameState.won = true
		title.text = "MENANG!"
		Sfx.play_music("win")
		Sfx.play("success")
		result.text = "Tasik bersinar emas (%d%%)! GF kembali. Kau dah tak kepam.\n\nTekan ENTER untuk tengok pengakhiran." % int(brightness * 100)
	else:
		title.text = "KALAH"
		Sfx.play("fail")
		result.text = "%s (%d%%)\n\nTekan ENTER untuk tengok pengakhiran." % [GameState.LOSE_TEXT["lake"], int(brightness * 100)]
