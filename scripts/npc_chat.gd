class_name NpcChat
extends Control
# Small speech-bubble toast with a typing indicator. NpcChat.show_on(parent, "hafiz_hub") or show_text(parent, who, text).

var who := ""
var body := ""
var t := 0.0
var life := 5.0
var typing_for := 0.8


static func show_on(parent: Node, key: String, secs := 5.0) -> NpcChat:
	var who_name := "Hafiz"
	if key.begins_with("gas_"):
		who_name = "Abang Pam"
	elif key.begins_with("mall_"):
		who_name = "Pak Guard"
	elif key.begins_with("ping_"):
		who_name = Story.GF_NAME
	var raw := Story.line(key)
	var idx := raw.find(": ")
	var msg := raw.substr(idx + 2) if idx >= 0 else raw
	return show_text(parent, who_name, msg, secs)


static func show_text(parent: Node, who_name: String, msg: String, secs := 5.0) -> NpcChat:
	var c := NpcChat.new()
	c.who = who_name
	c.body = msg
	c.life = secs
	parent.add_child(c)
	return c


func _ready() -> void:
	z_index = 60
	position = Vector2(14, 70)
	size = Vector2(300, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	Sfx.play("notify", -6.0)


func _process(delta: float) -> void:
	t += delta
	if t > life:
		queue_free()
	queue_redraw()


func _draw() -> void:
	var a := clampf(minf(t / 0.25, (life - t) / 0.4), 0.0, 1.0)
	var rr := Rect2(Vector2.ZERO, size)
	draw_style_box(Ui.box(Color(0.08, 0.02, 0.14, 0.95 * a), Color(Ui.PINK.r, Ui.PINK.g, Ui.PINK.b, a), 12, 3), rr)
	draw_circle(Vector2(30, 32), 18, Color(Ui.ORANGE.r, Ui.ORANGE.g, Ui.ORANGE.b, a))
	Ui.text(self, Vector2(23, 40), who.substr(0, 1), 20, Color(Ui.INK.r, Ui.INK.g, Ui.INK.b, a), 0)
	Ui.text(self, Vector2(58, 20), who, 12, Color(Ui.ORANGE.r, Ui.ORANGE.g, Ui.ORANGE.b, a), 0)
	if t < typing_for:
		for i in 3:
			var b := absf(sin(t * 8.0 + i * 0.8)) * 4.0
			draw_circle(Vector2(66 + i * 14, 42 - b), 3.5, Color(1, 1, 1, a))
		return
	var words := body.split(" ")
	var line := ""
	var y := 38.0
	for w in words:
		var tryl := w if line == "" else line + " " + w
		if Ui.text_width(tryl, 13) > size.x - 70.0 and line != "":
			Ui.text(self, Vector2(58, y), line, 13, Color(1, 1, 1, a), 0)
			y += 16.0
			line = w
		else:
			line = tryl
	Ui.text(self, Vector2(58, y), line, 13, Color(1, 1, 1, a), 0)
