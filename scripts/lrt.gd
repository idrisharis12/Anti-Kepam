extends ShowerBase
# LRT: front view of the card machine. Drag the card through the slot, not too fast, not too slow.
# Machine screen shows SUCCESS / GAGAL; retry until success. Then 5 moral questions (1 kuman per correct answer,
# no need to get all right), then the avatar walks into the LRT shower and washes.

const QUESTIONS := [
	["Berapa kali kita perlu mandi dalam sehari, secara am?", ["Seminggu sekali", "1-2 kali sehari", "5-6 kali sehari", "Bila bau je"], 1],
	["Apakah elemen penting yang disarankan untuk kebersihan diri?", ["Minyak wangi je", "Bedak dan gel rambut", "Sabun, cuci muka, syampu, gosok gigi", "Air kosong sudah cukup"], 2],
	["Apa yang perlu dilakukan untuk jaga kualiti kebersihan diri?", ["Potong kuku, tukar berus gigi tiap 3 bulan", "Tukar berus gigi tiap 3 tahun", "Gigit kuku bila bosan", "Kongsi berus gigi dengan kawan"], 0],
	["Apa yang patut anda pertimbangkan ketika guna fasiliti awam?", ["Ikut suka hati", "Tengok orang lain buat", "Tak payah fikir", "Common sense"], 3],
	["Apakah contoh terbaik ketika menggunakan tandas awam?", ["Beratur, jaga bersih, jangan rosak fasiliti", "Pintas barisan kalau terdesak", "Conteng dinding sebagai kenangan", "Biarkan lantai basah"], 0],
	["Apa tindakan anda bila nampak orang rosakkan fasiliti awam?", ["Tidak ambil endah", "Rekod dan viralkan", "Lapor kepada pihak berkuasa", "Lapor kepada Tuhan"], 2],
]
const MACHINE := Rect2(580, 130, 340, 330)
const SLOT_Y := 330.0
const MIN_T := 0.35
const MAX_T := 0.9

var phase := 0
var q := 0
var correct := 0
var swipe_start := 0.0
var swiping := false
var card := ColorRect.new()
var screen := ColorRect.new()
var screen_l: Label
var dlg: DialogueBox
var avatar: AvatarView
var walk_t := 0.0
var shower_t := 0.0
var door := ColorRect.new()


func _build() -> void:
	station_id = "lrt"
	time_limit = 0.0
	active = false
	bg.color = Color(0.1, 0.03, 0.12)
	add_backdrop("res://assets/lrt_bg.png")
	body.visible = false
	title.text = "LRT  -  Swipe kad, jawab soalan, lepas tu mandi."
	status.text = "Seret kad dari kiri ke kanan melalui slot. Jangan terlalu laju, jangan terlalu lambat."
	status.position = Vector2(555, 60)

	var m := ColorRect.new()
	m.position = MACHINE.position
	m.size = MACHINE.size
	m.color = Color(0.12, 0.1, 0.2)
	add_child(m)
	screen.position = MACHINE.position + Vector2(30, 20)
	screen.size = Vector2(280, 90)
	screen.color = Color(0.05, 0.15, 0.2)
	add_child(screen)
	screen_l = GameState.make_label(screen, "TAP KAD", Vector2(20, 22), 36)
	var slot := ColorRect.new()
	slot.position = Vector2(MACHINE.position.x + 20, SLOT_Y)
	slot.size = Vector2(300, 14)
	slot.color = Color.BLACK
	add_child(slot)
	card.size = Vector2(90, 56)
	card.color = Color(0.95, 0.75, 0.2)
	card.position = Vector2(MACHINE.position.x - 10, SLOT_Y - 50)
	add_child(card)
	GameState.make_label(card, "KAD", Vector2(24, 14), 18)

	dlg = DialogueBox.new()
	add_child(dlg)

	door.position = Vector2(330, 250)
	door.size = Vector2(110, 230)
	door.color = Color(0.2, 0.55, 0.6)
	door.visible = false
	add_child(door)
	avatar = AvatarView.new()
	avatar.position = Vector2(110, 500)
	avatar.visible = false
	add_child(avatar)


func _input(event: InputEvent) -> void:
	if phase != 0 or done:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and Rect2(card.position, card.size).grow(30).has_point(event.position):
			swiping = true
			Sfx.play("swipe", -4.0)
			swipe_start = Time.get_ticks_msec() / 1000.0
		elif not event.pressed and swiping:
			swiping = false
			_judge(Time.get_ticks_msec() / 1000.0 - swipe_start, card.position.x + card.size.x > MACHINE.end.x - 80)
	elif event is InputEventMouseMotion and swiping:
		card.position.x = clampf(event.position.x - card.size.x / 2, MACHINE.position.x - 10, MACHINE.end.x - card.size.x + 10)


func _judge(dt: float, reached: bool) -> void:
	var msg := ""
	if not reached:
		msg = "GAGAL: kad tak sampai hujung"
	elif dt < MIN_T:
		msg = "GAGAL: terlalu laju"
	elif dt > MAX_T:
		msg = "GAGAL: terlalu lambat"
	if msg == "":
		screen.color = Color(0.05, 0.4, 0.15)
		screen_l.text = "SUCCESS"
		Sfx.play("success")
		status.text = "Kad berjaya! Staf kaunter ada soalan..."
		phase = 1
		await get_tree().create_timer(1.1).timeout
		_start_questions()
	else:
		screen.color = Color(0.5, 0.05, 0.1)
		screen_l.text = "GAGAL"
		Sfx.play("fail", -4.0)
		status.text = msg + ". Cuba lagi."
		await get_tree().create_timer(0.9).timeout
		if phase == 0:
			screen.color = Color(0.05, 0.15, 0.2)
			screen_l.text = "TAP KAD"
			card.position.x = MACHINE.position.x - 10


func _start_questions() -> void:
	phase = 2
	status.text = ""
	dlg.open("Staf Kaunter", load("res://assets/staff_portrait.png"))
	await dlg.say("Eh, kau. Muka macam orang tak mandi tiga hari.")
	await dlg.say("Nak masuk tandas LRT? Jawab dulu %d soalan kebersihan. Setiap jawapan betul, aku bagi satu kuman. Tekan A-D atau klik." % QUESTIONS.size())
	for i in QUESTIONS.size():
		var d: Array = QUESTIONS[i]
		var pick: int = await dlg.ask("(%d/%d)  %s" % [i + 1, QUESTIONS.size(), d[0]], d[1])
		if d[2] == pick:
			correct += 1
			GameState.kuman += 1
			Sfx.play("coin")
			await dlg.say("Hmm, boleh tahan. +1 kuman.")
		else:
			Sfx.play("fail", -6.0)
			await dlg.say("...Betul ke jawapan tu? Takpelah.")
	await dlg.say("Betul %d daripada %d. Dah, pergi mandi. Jangan lama-lama." % [correct, QUESTIONS.size()])
	dlg.close()
	phase = 3
	walk_t = 0.0
	door.visible = true
	avatar.visible = true
	status.text = "Boy masuk tandas LRT..."


func _tick(delta: float) -> void:
	if phase == 3:
		walk_t += delta
		avatar.position.x = lerpf(110.0, 385.0, clampf(walk_t / 2.0, 0.0, 1.0))
		if walk_t >= 2.0:
			phase = 4
			shower_t = 0.0
			avatar.set_showering(true)
			Sfx.loop("water_loop")
			status.text = "Boy mandi di LRT..."
			body.visible = true
	elif phase == 4:
		shower_t += delta
		for i in PARTS.size():
			progress[i] = minf(1.0, shower_t / 4.0)
		if shower_t >= 4.5:
			done = true
			Sfx.stop_loop("water_loop")
			GameState.finish_station("lrt", clampf(0.4 + correct * 0.1, 0.4, 1.0))
