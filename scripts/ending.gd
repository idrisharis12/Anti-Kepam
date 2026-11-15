extends ShowerBase
# Ending: the golden lake is the final, biggest shower. Brightness = 70% average station score + 30% this shower.
# Also shows the lose screens (viral / spread / gf) when GameState.lose_reason is set.

const WIN_BRIGHTNESS := 0.6

var lake: TextureRect
var result: Label
var sub: Label
var head: Label
var result_shown := false
var early_lose := false
var base_avg := 0.0
var bright := 0.0
var verdict := 0
var t := 0.0
var jump_t := 0.0
var jumping := false
var splash_t := -1.0
var diver: AvatarView
const JUMP_FROM := Vector2(70, 250)
const JUMP_TO := Vector2(270, 395)
const JUMP_DUR := 1.6


func _build() -> void:
	station_id = "lake"
	Sfx.stop_all_loops()
	Sfx.play_music("lake_sad" if GameState.lose_reason != "" else "lake")
	time_limit = 30.0
	GameState.running = false
	bg.color = Color(0.1, 0.03, 0.12)
	lake = add_backdrop("res://assets/lake_bg.png")
	lake.modulate = Color(0.3, 0.3, 0.4)
	for l in [title, status, body]:
		l.visible = false
	var panel := Ui.panel(self, Rect2(556, 10, 388, 474), Ui.PINK)
	move_child(panel, 2)
	head = Ui.label(self, "GOLDEN LAKE", Vector2(556, 16), 34, Ui.ORANGE, 388)
	head.add_theme_constant_override("outline_size", 8)
	sub = Ui.label(self, "Mandi terakhir!", Vector2(556, 62), 14, Ui.PINK, 388)
	Ui.rule(self, Vector2(574, 90), 352, Ui.PINK)
	result = Ui.label(self, "", Vector2(574, 100), 16, Ui.CREAM, 352, false)
	var ov := Overlay.new()
	ov.painter = _paint
	ov.z_index = 6
	add_child(ov)
	if GameState.lose_reason != "":
		active = false
		done = true
		result_shown = true
		early_lose = true
		verdict = -1
		head.text = "KALAH"
		head.add_theme_color_override("font_color", Color(1.0, 0.3, 0.4))
		sub.text = "Pengakhiran menunggu..."
		result.text = GameState.LOSE_TEXT[GameState.lose_reason]
		return
	base_avg = GameState.average_score()
	diver = AvatarView.new()
	diver.dirt = 0.15
	diver.position = JUMP_FROM
	diver.scale = Vector2(1.2, 1.2)
	diver.z_index = 5
	add_child(diver)
	jumping = true
	active = false
	Sfx.play("notify")
	result.text = "Terjun! Tahan SPACE untuk mandi penuh. Tasik cerah ikut skor semua mandi tadi."


func _process(delta: float) -> void:
	t += delta
	if jumping:
		_jump(delta)
		return
	if result_shown:
		if Input.is_key_pressed(KEY_ENTER) or Input.is_key_pressed(KEY_KP_ENTER):
			set_process(false)
			get_tree().change_scene_to_file("res://scenes/outro.tscn")
		return
	super._process(delta)
	if active and not done and Input.is_key_pressed(KEY_SPACE):
		Sfx.loop("water_loop")
	else:
		Sfx.stop_loop("water_loop")
	var clean := 0.0
	for p in progress:
		clean += p
	clean /= PARTS.size()
	bright = base_avg * 0.7 + clean * 0.3
	_set_glow(bright)


func _jump(delta: float) -> void:
	jump_t += delta
	var k := clampf(jump_t / JUMP_DUR, 0.0, 1.0)
	if k < 1.0:
		var p := JUMP_FROM.lerp(JUMP_TO, k)
		p.y -= sin(k * PI) * 130.0
		diver.position = p
		diver.rotation = k * TAU * 1.5
	elif splash_t < 0.0:
		splash_t = 0.0
		diver.rotation = 0.0
		diver.position = JUMP_TO + Vector2(0, 22)
		diver.scale = Vector2(1.2, 0.6)
		Sfx.play("success")
	else:
		splash_t += delta
		diver.modulate.a = lerpf(1.0, 0.7, minf(splash_t, 1.0))
		diver.dirt = maxf(0.0, diver.dirt - delta * 0.3)
		diver.position.y = JUMP_TO.y + 22 + sin(splash_t * 3.0) * 3.0
		if splash_t > 1.6:
			jumping = false
			active = true
			result.text = "Terjun! Tahan SPACE untuk mandi penuh. Tasik cerah ikut skor semua mandi tadi."


func _exit_tree() -> void:
	Sfx.stop_loop("water_loop")


func _set_glow(b: float) -> void:
	var k := clampf(b / 0.9, 0.0, 1.0)
	lake.modulate = Color(0.3, 0.3, 0.4).lerp(Color(1.15, 1.05, 0.9), k)


func _bar(o: CanvasItem, r: Rect2, v: float, col: Color) -> void:
	o.draw_style_box(Ui.box(Color(0.03, 0.0, 0.07), Color(0.4, 0.2, 0.5), 5, 2), r)
	var w := (r.size.x - 6.0) * clampf(v, 0.0, 1.0)
	if w > 1.0:
		o.draw_rect(Rect2(r.position.x + 3, r.position.y + 3, w, r.size.y - 6), col)
		o.draw_rect(Rect2(r.position.x + 3, r.position.y + 3, w, (r.size.y - 6) * 0.35), Color(1, 1, 1, 0.18))


func _paint(o: Overlay) -> void:
	if not early_lose:
		var k := clampf(bright / 0.9, 0.0, 1.0)
		if k > 0.25:
			var bl := (k - 0.25) / 0.75
			o.draw_circle(Vector2(270, 200), 190.0, Color(1.0, 0.85, 0.4, 0.12 * bl))
			o.draw_circle(Vector2(270, 200), 120.0, Color(1.0, 0.9, 0.5, 0.14 * bl))
			Fx.sparkles(o, Rect2(0, 300, 540, 200), t, bl, int(6 + bl * 20))
	if splash_t >= 0.0 and splash_t < 1.3:
		var sk := splash_t / 1.3
		for i in 14:
			var a := -PI * (0.1 + 0.8 * i / 13.0)
			var d := Vector2(cos(a), sin(a)) * (30.0 + 70.0 * sk) * (0.6 + 0.4 * (i % 3) / 2.0)
			d.y += 90.0 * sk * sk
			o.draw_circle(JUMP_TO + Vector2(0, 20) + d, 6.0 * (1.0 - sk) + 1.5, Color(0.8, 0.95, 1.0, 1.0 - sk))
		o.draw_arc(JUMP_TO + Vector2(0, 28), 20 + 90 * sk, 0, TAU, 32, Color(1, 1, 1, 0.8 * (1.0 - sk)), 3.0)
	if jumping and jump_t < JUMP_DUR:
		Ui.text(o, Vector2(60, 110), "TERJUN!", 28, Ui.ORANGE, 6)
	if early_lose:
		var reason: String = GameState.lose_reason
		Fx.draw_newspaper(o, Rect2(30, 70, 480, 300), Story.line("head_" + reason), Story.line("sub_" + reason), 1.0)
		var c := Vector2(750, 270)
		o.draw_circle(c, 98, Ui.INK)
		o.draw_circle(c, 92, Color(0.15, 0.1, 0.3))
		BoyFace.draw_face(o, c, 84.0, 1.0, t)
		Ui.text(o, Vector2(750 - Ui.text_width("Kau dah tak rasa apa-apa.", 14) / 2.0, 400), "Kau dah tak rasa apa-apa.", 14, Color(0.7, 0.75, 0.9), 3)
	else:
		Ui.text(o, Vector2(574, 196), "MANDI TERAKHIR", 13, Ui.ORANGE, 4)
		for i in PARTS.size():
			var y := 206.0 + i * 28.0
			var mark := active and i == current and not result_shown
			Ui.text(o, Vector2(574, y + 17), PARTS[i], 14, Ui.GREEN if progress[i] >= 1.0 else (Color.WHITE if mark else Ui.CREAM), 3)
			_bar(o, Rect2(660, y, 266, 22), progress[i], Ui.GREEN if progress[i] >= 1.0 else Ui.WATER)
		var tl := clampf(time_left / time_limit, 0.0, 1.0) if not result_shown else 0.0
		Ui.text(o, Vector2(574, 340), "MASA", 13, Ui.ORANGE, 4)
		_bar(o, Rect2(660, 324, 266, 22), tl, Ui.ORANGE if tl > 0.25 else Color(1.0, 0.3, 0.35))
		Ui.text(o, Vector2(574, 376), "KECERAHAN TASIK", 13, Ui.ORANGE, 4)
		var pct := "%d%%" % int(bright * 100.0)
		Ui.text(o, Vector2(926 - Ui.text_width(pct, 14), 376), pct, 14, Color.WHITE, 4)
		_bar(o, Rect2(574, 384, 352, 22), bright, Color(1.0, 0.85, 0.3))
		var mx := 574.0 + 3.0 + (352.0 - 6.0) * WIN_BRIGHTNESS
		o.draw_line(Vector2(mx, 380), Vector2(mx, 410), Color.WHITE, 2.0)
		Ui.text(o, Vector2(mx - 22, 424), "CUKUP 60%", 10, Color(0.85, 0.85, 0.95), 3)
	if result_shown:
		var pulse := 0.55 + 0.45 * sin(t * 4.0)
		o.draw_style_box(Ui.box(Color(0.35, 0.02, 0.2, 0.9), Color(1.0, 0.72, 0.15, pulse), 10, 3), Rect2(574, 436, 352, 40))
		Ui.text(o, Vector2(750 - Ui.text_width("Tekan ENTER untuk tengok pengakhiran", 15) / 2.0, 462), "Tekan ENTER untuk tengok pengakhiran", 15, Color.WHITE, 3)


func _on_finished(score: float) -> void:
	Sfx.stop_loop("water_loop")
	bright = base_avg * 0.7 + score * 0.3
	_set_glow(bright)
	result_shown = true
	if bright >= WIN_BRIGHTNESS:
		GameState.won = true
		verdict = 1
		if diver != null:
			diver.dirt = 0.0
			diver.clean_look = true
			diver.modulate = Color(3.0, 3.0, 3.0)
			create_tween().tween_property(diver, "modulate", Color.WHITE, 0.8)
		head.text = "MENANG!"
		head.add_theme_color_override("font_color", Ui.GREEN)
		sub.text = "Golden Lake bersinar emas"
		Sfx.play_music("win")
		Sfx.play("success")
		result.text = Loc.t("Tasik bersinar emas (%d%%)! GF kembali. Kau dah tak kepam.") % int(bright * 100)
	else:
		verdict = -1
		head.text = "KALAH"
		head.add_theme_color_override("font_color", Color(1.0, 0.3, 0.4))
		sub.text = "Tasik tak cukup cerah"
		Sfx.play("fail")
		result.text = "%s (%d%%)" % [Loc.t(GameState.LOSE_TEXT["lake"]), int(bright * 100)]
