class_name NewsTicker
extends Control
# Scrolling Berita Kepam 26 bar for the hub: add_child(NewsTicker.new()), then set position/size if needed.

const LABEL_W := 108.0

var t := 0.0
var text := ""
var scroll := Overlay.new()


func _ready() -> void:
	z_index = 8
	position = Vector2(0, 40)
	size = Vector2(540, 22)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	text = Story.news_text()
	var clip := Control.new()
	clip.position = Vector2(LABEL_W, 0)
	clip.size = Vector2(size.x - LABEL_W, size.y)
	clip.clip_contents = true
	clip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(clip)
	scroll.painter = _paint_text
	clip.add_child(scroll)


func _process(delta: float) -> void:
	t += delta
	queue_redraw()


func _draw() -> void:
	var hot := GameState.spread > 60.0
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.65, 0.04, 0.1, 0.92) if hot else Color(0.35, 0.05, 0.3, 0.92))
	draw_rect(Rect2(Vector2.ZERO, size), Ui.INK, false, 2.0)
	draw_rect(Rect2(0, 0, LABEL_W, size.y), Ui.ORANGE)
	Ui.text(self, Vector2(10, 16), "BERITA 26", 13, Ui.INK, 0)


func _paint_text(o: Overlay) -> void:
	var w := Ui.text_width(text, 13) + 60.0
	var x := (size.x - LABEL_W) - fposmod(t * 55.0, w + size.x - LABEL_W)
	Ui.text(o, Vector2(x, 16), text, 13, Color.WHITE, 0)
