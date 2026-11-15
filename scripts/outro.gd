extends Node2D
# Ending cinematic: win (golden lake, GF comes back) or one of the lose endings. ENTER skips.

const SCENES := {
	"win": {"bg": "res://assets/lake_bg.png", "tint": Color(1.1, 1.0, 0.85), "music": "win"},
	"lake": {"bg": "res://assets/lake_bg.png", "tint": Color(0.35, 0.35, 0.5), "music": "lake_sad"},
	"viral": {"bg": "res://assets/mall_bg.png", "tint": Color(0.7, 0.45, 0.6), "music": "lake_sad"},
	"spread": {"bg": "res://assets/hub_bg.png", "tint": Color(0.6, 0.85, 0.4), "music": "mall"},
	"gf": {"bg": "res://assets/intro_bg.png", "tint": Color(0.35, 0.35, 0.5), "music": "lake_sad"},
}

var key := "win"
var pic: Sprite2D
var caption: Label
var ticker: Label
var ticker_bar: ColorRect
var cover: ColorRect
var skipped := false
var t := 0.0
var ready_to_leave := false
var gas := 0.0
var flies := 0.0
var gf_a := 0.0
var gf_g := 0.15
var boy: AvatarView
var tw_scale: Tween
var tw_tint: Tween
const GF_TEX := preload("res://assets/gf_portrait.png")
var sparkle := 0.0
var cafe := 0.0
var hearts := 0.0
var phone_a := 0.0
var phone_lines: Array = []
var credits_on := false
var credits_t := 0.0


func _ready() -> void:
	Sfx.stop_all_loops()
	key = "win" if GameState.won else (GameState.lose_reason if GameState.lose_reason != "" else "lake")
	var d: Dictionary = SCENES[key]
	Sfx.play_music(d["music"])

	pic = Sprite2D.new()
	pic.texture = load(d["bg"])
	var tex_size: Vector2 = pic.texture.get_size()
	var k := maxf(960.0 / tex_size.x, 540.0 / tex_size.y) * 1.1
	pic.scale = Vector2(k, k)
	pic.position = Vector2(480, 270)
	pic.modulate = Color.BLACK
	add_child(pic)
	tw_tint = create_tween()
	tw_tint.tween_property(pic, "modulate", d["tint"], 2.5)
	tw_scale = create_tween()
	tw_scale.tween_property(pic, "scale", Vector2(k * 1.15, k * 1.15), 40.0).set_trans(Tween.TRANS_SINE)

	var fx := Overlay.new()
	fx.painter = _paint
	add_child(fx)
	boy = AvatarView.new()
	boy.position = Vector2(480, 520)
	boy.scale = Vector2(2.6, 2.6)
	boy.visible = false
	add_child(boy)

	for y in [0.0, 540.0 - 56.0]:
		var bar := ColorRect.new()
		bar.color = Color.BLACK
		bar.position = Vector2(0, y)
		bar.size = Vector2(960, 56)
		add_child(bar)

	caption = Label.new()
	caption.size = Vector2(840, 120)
	caption.position = Vector2(60, 330)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_font_size_override("font_size", 28)
	caption.add_theme_color_override("font_color", Color(1, 0.96, 0.88))
	caption.add_theme_color_override("font_outline_color", Color.BLACK)
	caption.add_theme_constant_override("outline_size", 10)
	caption.modulate.a = 0.0
	add_child(caption)

	ticker_bar = ColorRect.new()
	ticker_bar.color = Color(0.75, 0.05, 0.1)
	ticker_bar.position = Vector2(0, 440)
	ticker_bar.size = Vector2(960, 40)
	ticker_bar.visible = false
	add_child(ticker_bar)
	ticker = Label.new()
	ticker.add_theme_font_size_override("font_size", 22)
	ticker.add_theme_color_override("font_color", Color.WHITE)
	ticker.position = Vector2(960, 4)
	ticker_bar.add_child(ticker)
	ticker_bar.clip_contents = true

	var skip := Label.new()
	skip.text = "ENTER untuk langkau"
	skip.position = Vector2(780, 508)
	skip.add_theme_font_size_override("font_size", 14)
	skip.modulate.a = 0.5
	add_child(skip)

	cover = ColorRect.new()
	cover.size = Vector2(960, 540)
	cover.color = Color.BLACK
	cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cover.modulate.a = 0.0
	add_child(cover)
	_run()


func hold(sec: float) -> void:
	var el := 0.0
	while el < sec and not skipped:
		await get_tree().process_frame
		el += get_process_delta_time()


func say(text: String, dur: float) -> void:
	caption.text = text
	create_tween().tween_property(caption, "modulate:a", 1.0, 0.7)
	await hold(0.7 + dur)
	create_tween().tween_property(caption, "modulate:a", 0.0, 0.5)
	await hold(0.6)


func news(text: String) -> void:
	ticker_bar.visible = true
	text = Loc.t(text)
	ticker.text = Loc.t("BERITA KEPAM 26  |  ") + text + "          " + text
	ticker.position.x = 960
	Sfx.play("notify")
	create_tween().tween_property(ticker, "position:x", -1700.0, 9.0)


func _run() -> void:
	await hold(1.5)
	match key:
		"win":
			await say("Dia terjun ke Golden Lake.", 2.2)
			boy.visible = true
			boy.dirt = 1.0
			boy.position = Vector2(480, 520)
			await say("Air tasik berkilau emas, bersih dan hangat.", 2.4)
			create_tween().tween_property(boy, "dirt", 0.0, 2.0)
			create_tween().tween_property(self, "sparkle", 1.0, 2.0)
			await hold(2.0)
			boy.clean_look = true
			boy.modulate = Color(3.0, 3.0, 3.0)
			create_tween().tween_property(boy, "modulate", Color.WHITE, 0.8)
			Sfx.play("success")
			await say("Serabut hilang. Bau hilang. Dia bersinar.", 3.0)
			await say("Untuk pertama kali dalam seminggu, dia wangi.", 2.8)
			phone_lines = ["Kau: Jumpa sekejap je?"]
			create_tween().tween_property(self, "phone_a", 1.0, 0.5)
			Sfx.play("notify")
			await say("Dia hantar mesej kepada GF.", 2.6)
			phone_lines = ["Kau: Jumpa sekejap je?", "Sayang: ...okay. Cafe biasa."]
			Sfx.play("notify")
			await say("Dia balas.", 2.2)
			create_tween().tween_property(self, "phone_a", 0.0, 0.4)
			boy.visible = false
			sparkle = 0.0
			await shot("res://assets/cafe_bg.png", Color(1.1, 1.0, 0.9), 1.12)
			cafe = 1.0
			await say("Di cafe, GF menunggu. Dia berhenti bila bau yang biasa tak ada.", 3.4)
			await say("\"You... wangi. You betul-betul berubah.\"", 3.0)
			await say("Mereka sembang lama. Ketawa macam dulu.", 3.0)
			create_tween().tween_property(self, "hearts", 1.0, 1.5)
			var br := Story.branch()
			await say(Story.line("end_" + br + "_cap"), 3.0)
			await say("\"" + Story.line("end_" + br) + "\"", 3.0)
			await say("Dia jatuh cinta balik.", 3.0)
			cafe = 0.0
			hearts = 0.0
			await shot("res://assets/hub_bg.png", Color(1.0, 0.7, 0.5), 1.2)
			boy.visible = true
			boy.dirt = 0.0
			boy.clean_look = true
			boy.scale = Vector2(1.8, 1.8)
			boy.position = Vector2(120, 500)
			create_tween().tween_property(boy, "position:x", 800.0, 7.0)
			await say("Petang itu, dia berjalan pulang.", 3.2)
			await say("Hati ringan. Langkah ringan.", 3.0)
			boy.visible = false
			await shot("res://assets/home_bg.png", Color(1.05, 0.95, 0.9), 1.1)
			Sfx.play("notify")
			phone_lines = ["Sayang: can we fix back our relationships?"]
			create_tween().tween_property(self, "phone_a", 1.0, 0.5)
			await say("Masuk rumah, telefon bergetar.", 3.4)
			await hold(2.5)
			create_tween().tween_property(self, "phone_a", 0.0, 0.4)
			await say("Dia senyum.", 2.0)
			await say("\"Aku tak kepam.\"", 2.4)
			await say("ANTI-KEPAM\nTAMAT", 3.0)
			if Story.is_secret():
				await hold(0.5)
				phone_lines = ["Kau: " + Story.line("secret_1").substr(8)]
				create_tween().tween_property(self, "phone_a", 1.0, 0.4)
				Sfx.play("notify")
				await say(Story.line("secret_1"), 3.0)
				await say(Story.line("secret_2"), 2.6)
				create_tween().tween_property(self, "phone_a", 0.0, 0.4)
				Sfx.play("success")
				await say(Story.line("secret_cap"), 3.4)
			await _credits()
		"lake":
			await say("Dia terapung di tasik yang malap.", 2.4)
			await say("Sudah empat tempat dia mandi. Masih tak cukup.", 2.8)
			Sfx.play("notify")
			await say("Telefon senyap. Tiada mesej baru.", 2.8)
			await _lose_tail()
		"viral":
			await say(Story.line("lipas_viral_1"), 2.4)
			news(Story.line("lipas_viral_news"))
			await hold(5.0)
			await say("Sejuta tontonan dalam semalam. Namanya kini: \"Budak Kepam\".", 3.0)
			await _lose_tail()
		"spread":
			await say("Bau itu sudah terlalu kuat.", 2.4)
			news("SATU NEGERI KEPAM! SEMUA SEKOLAH DAN PEJABAT DITUTUP.")
			await hold(5.0)
			await say("Pihak berkuasa mengisytiharkan darurat kepam.", 2.8)
			await _lose_tail()
		"gf":
			await say("Dia masih berlari dari satu tempat ke satu tempat.", 2.6)
			Sfx.play("notify")
			await say("Instagram: \"Alhamdulillah, selamat bernikah.\"", 3.0)
			await say("Pengantin lelakinya... bukan dia.", 2.6)
			await _lose_tail()
	create_tween().tween_property(cover, "modulate:a", 1.0, 1.5)
	await hold(1.8)
	_leave()


func shot(path: String, tint: Color, zoom_to := 1.3) -> void:
	create_tween().tween_property(cover, "modulate:a", 1.0, 0.7)
	await hold(0.8)
	pic.texture = load(path)
	var ts: Vector2 = pic.texture.get_size()
	var k := maxf(960.0 / ts.x, 540.0 / ts.y) * 1.08
	pic.scale = Vector2(k, k)
	if tw_tint:
		tw_tint.kill()
	pic.modulate = tint
	if tw_scale:
		tw_scale.kill()
	tw_scale = create_tween()
	tw_scale.tween_property(pic, "scale", Vector2(k * zoom_to, k * zoom_to), 30.0).set_trans(Tween.TRANS_SINE)
	ticker_bar.visible = false
	create_tween().tween_property(cover, "modulate:a", 0.0, 0.7)
	await hold(0.8)


func _credits() -> void:
	credits_t = 0.0
	credits_on = true
	await shot("res://assets/hub_bg.png", Color(0.45, 0.35, 0.55), 1.1)
	boy.visible = false
	var el := 0.0
	while el < 13.0 and not skipped:
		await get_tree().process_frame
		el += get_process_delta_time()
		credits_t = el
	credits_on = false


func _paint_credits(o: Overlay) -> void:
	o.draw_rect(Rect2(0, 0, 960, 540), Color(0.05, 0.0, 0.1, 0.55))
	var cast := [["credits_title", ""], ["credits_boy", "boy"], ["credits_gf", "gf"], ["credits_friend", "friend"], ["credits_lipas", "lipas"], ["credits_thanks", ""]]
	var y0 := 560.0 - credits_t * 42.0
	for i in cast.size():
		var y: float = y0 + i * 118.0
		if y < 20.0 or y > 540.0:
			continue
		var who: String = cast[i][1]
		var label := Story.line(cast[i][0])
		var fs := 34 if i == 0 else 20
		var cx := 480.0
		match who:
			"boy":
				var av := Vector2(cx - 150.0, y + 30.0)
				_credit_boy(o, av)
			"gf":
				BoyFace.draw_gf_mood(o, Vector2(cx - 150.0, y + 8.0), 30.0, GF_TEX, "happy", t)
			"friend":
				var fc := Vector2(cx - 150.0, y + 8.0)
				o.draw_circle(fc, 31, Ui.INK)
				BoyFace.draw_mood(o, fc, 28.0, "happy", t)
			"lipas":
				Fx.draw_lipas(o, Vector2(cx - 150.0, y + 8.0), 1.5, t, true, 0.6)
		var off := 40.0 if who != "" else -Ui.text_width(label, fs) / 2.0 + 0.0
		var tx := (cx - 100.0) if who != "" else (cx + off)
		Ui.text(o, Vector2(tx, y + 14.0), label, fs, Ui.ORANGE if i == 0 else Color.WHITE, 5)


func _credit_boy(o: Overlay, p: Vector2) -> void:
	var f := int(t * 6.0) % 4
	var src := Rect2(f * 160.0, 142.0, 160.0, 142.0)
	o.draw_texture_rect_region(load("res://assets/boy_clean.png"), Rect2(p + Vector2(-34, -60), Vector2(68, 60)), src)


func _lose_tail() -> void:
	await shot("res://assets/intro_bg.png", Color(0.3, 0.32, 0.4))
	boy.visible = true
	boy.modulate = Color(0.8, 0.9, 0.6)
	create_tween().tween_property(self, "flies", 1.0, 3.0)
	create_tween().tween_property(self, "gas", 0.3, 8.0)
	await say("Dia berhenti mandi.", 2.2)
	await say("Sehari. Dua hari. Seminggu.", 2.4)
	await say("Lalat pun lari dari dia.", 2.6)
	boy.visible = false
	flies = 0.0
	await shot("res://assets/hub_bg.png", Color(0.6, 0.75, 0.5), 1.2)
	create_tween().tween_property(self, "gas", 1.0, 13.0)
	await say("Bau itu tak berhenti di rumahnya.", 2.6)
	await say("Ia merebak ke jalan, ke bandar, ke seluruh negeri.", 3.0)
	news("AMARAN GLOBAL: SELURUH DUNIA KEPAM. PENDUDUK DISARANKAN PAKAI GAS MASK.")
	await say("Burung jatuh dari langit. Orang berhenti bernafas.", 3.2)
	await say("Dunia sekarang berbau macam dia.", 2.8)
	await shot("res://assets/wedding.png", Color(0.75, 0.8, 0.85), 1.15)
	gas = 0.2
	await say("Tapi di satu taman yang masih wangi...", 2.6)
	await say("Dia sedang berkahwin. Dengan lelaki lain.", 3.0)
	await say("Semua orang tepuk tangan. Tiada siapa jemput budak kepam.", 3.2)
	await say("Dia hanya mampu menonton dari balik pagar.", 3.0)
	create_tween().tween_property(self, "gf_a", 1.0, 1.5)
	create_tween().tween_property(self, "gf_g", 1.0, 9.0)
	await say("Dia tunggu satu mesej yang tak pernah datang.", 3.0)
	await say("Kecewa...", 2.2)
	await say("Sedih...", 2.2)
	await say("Lama-lama, dia berhenti rasa apa-apa.", 3.4)
	await say("TAMAT\nKEPAM SELAMANYA", 3.0)


func _paint(o: Overlay) -> void:
	if credits_on:
		_paint_credits(o)
		return
	if gas > 0.01:
		o.draw_rect(Rect2(0, 0, 960, 540), Color(0.22, 0.45, 0.04, gas * 0.5))
		for i in 16:
			var x := fmod(i * 173.0 + t * (10.0 + i), 1100.0) - 70.0
			var y := 540.0 - fmod(i * 97.0 + t * (14.0 + i * 2.0), 600.0) + 40.0
			var r := 60.0 + (i % 5) * 22.0
			o.draw_circle(Vector2(x, y), r, Color(0.5, 0.85, 0.2, gas * 0.22))
	if flies > 0.01:
		for i in 12:
			var a := t * (2.0 + i * 0.3) + i
			var c := Vector2(480, 300) + Vector2(cos(a), sin(a * 1.3)) * (70.0 + i * 9.0) * flies
			o.draw_circle(c, 2.5, Color(0.05, 0.05, 0.05))
			o.draw_line(c, c + Vector2(3, -3), Color(0.8, 0.9, 1.0, 0.7), 1.5)
		for i in 5:
			var pts := PackedVector2Array()
			for k in 14:
				pts.append(Vector2(420 + i * 30 + sin(t * 2.0 + k * 0.7 + i) * 9.0, 460 - k * 22.0))
			o.draw_polyline(pts, Color(0.5, 0.9, 0.2, 0.55 * flies), 4.0)
	if sparkle > 0.01:
		for i in 18:
			var a := t * 1.5 + i * 2.4
			var c := Vector2(480, 330) + Vector2(cos(a * 0.7 + i), sin(a + i * 0.5) * 0.8) * (60.0 + i * 8.0)
			var r := (2.0 + (i % 3) * 1.5) * (0.6 + 0.4 * sin(t * 5.0 + i))
			o.draw_circle(c, r, Color(1, 0.95, 0.5, 0.85 * sparkle))
			o.draw_line(c - Vector2(r * 2.2, 0), c + Vector2(r * 2.2, 0), Color(1, 1, 0.8, 0.6 * sparkle), 1.5)
			o.draw_line(c - Vector2(0, r * 2.2), c + Vector2(0, r * 2.2), Color(1, 1, 0.8, 0.6 * sparkle), 1.5)
	if cafe > 0.01:
		o.draw_circle(Vector2(480, 205), 104, Color(0.1, 0.0, 0.13))
		BoyFace.draw_gf_mood(o, Vector2(480, 205), 98.0, GF_TEX, "happy", t)
	if hearts > 0.01:
		for i in 8:
			var ph := fmod(t * 0.4 + i * 0.125, 1.0)
			var hc := Vector2(380 + i * 30 + sin(t * 2.0 + i) * 12.0, 330 - ph * 200.0)
			var hr := 9.0 * hearts
			o.draw_circle(hc + Vector2(-hr * 0.5, 0), hr * 0.6, Color(1, 0.3, 0.5, 1.0 - ph))
			o.draw_circle(hc + Vector2(hr * 0.5, 0), hr * 0.6, Color(1, 0.3, 0.5, 1.0 - ph))
			o.draw_colored_polygon(PackedVector2Array([hc + Vector2(-hr * 1.05, hr * 0.2), hc + Vector2(hr * 1.05, hr * 0.2), hc + Vector2(0, hr * 1.5)]), Color(1, 0.3, 0.5, 1.0 - ph))
	if phone_a > 0.01 and phone_lines.size() > 0:
		var ph_r := Rect2(40, 74, 300, 70 + phone_lines.size() * 52)
		o.draw_style_box(Ui.box(Color(0.06, 0.02, 0.1, 0.95 * phone_a), Color(1, 0.4, 0.7, phone_a), 16, 3), ph_r)
		BoyFace.draw_portrait(o, ph_r.position + Vector2(28, 28), 18.0, GF_TEX, Color(1, 1, 1, phone_a))
		Ui.text(o, ph_r.position + Vector2(56, 34), "Sayang", 18, Color(1, 1, 1, phone_a), 0)
		o.draw_line(ph_r.position + Vector2(12, 54), ph_r.position + Vector2(288, 54), Color(1, 0.4, 0.7, 0.5 * phone_a), 1.5)
		for i in phone_lines.size():
			var mine: bool = phone_lines[i].begins_with("Kau")
			var bx := Rect2(ph_r.position.x + 14, ph_r.position.y + 64 + i * 52, 272, 42)
			o.draw_style_box(Ui.box(Color(0.15, 0.5, 0.3, phone_a) if mine else Color(0.3, 0.12, 0.4, phone_a), Color(0, 0, 0, 0), 12, 0), bx)
			var msg: String = phone_lines[i].substr(phone_lines[i].find(":") + 2)
			Ui.text(o, bx.position + Vector2(10, 26), msg, 14, Color(1, 1, 1, phone_a), 0)
	if gf_a > 0.01:
		o.draw_rect(Rect2(0, 0, 960, 540), Color(0, 0, 0, gf_a * 0.82))
		if gf_a > 0.4:
			var c := Vector2(480, 205)
			var sh := Vector2(sin(t * 40.0), cos(t * 33.0)) * 2.0 * clampf(1.0 - gf_g, 0.0, 1.0) * clampf(gf_g * 4.0, 0.0, 1.0)
			o.draw_circle(c, 130, Color(0.1, 0.0, 0.13, gf_a))
			var gray := Color.WHITE.lerp(Color(0.5, 0.52, 0.6), gf_g)
			gray.a = gf_a
			BoyFace.draw_portrait(o, c + sh, 122.0, GF_TEX, gray)


func _leave() -> void:
	if ready_to_leave:
		return
	ready_to_leave = true
	GameState.reset()
	get_tree().change_scene_to_file("res://scenes/menu.tscn")


func _process(delta: float) -> void:
	t += delta


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER):
		skipped = true
