class_name AvatarView
extends Node2D
# Front-facing boy from the sprite sheet. Procedural poses: nod (0 upright .. 1 head down), slap, shower.

const CELL := Vector2(160, 142)

var sprite := Sprite2D.new()
var water := CPUParticles2D.new()
var zzz := Label.new()
var bubble := Label.new()
var nod := 0.0
var showering := false
var t := 0.0
var flash := 0.0


func _ready() -> void:
	sprite.texture = load("res://assets/boy_sheet.png")
	sprite.region_enabled = true
	sprite.region_rect = Rect2(0, 0, CELL.x, CELL.y)
	sprite.centered = false
	sprite.offset = Vector2(-CELL.x / 2, -CELL.y)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	add_child(sprite)

	water.emitting = false
	water.amount = 80
	water.lifetime = 0.7
	water.direction = Vector2.DOWN
	water.spread = 12.0
	water.gravity = Vector2(0, 900)
	water.initial_velocity_min = 120.0
	water.initial_velocity_max = 200.0
	water.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	water.emission_rect_extents = Vector2(26, 2)
	water.scale_amount_min = 2.0
	water.scale_amount_max = 3.5
	water.color = Color(0.6, 0.85, 1.0, 0.9)
	water.position = Vector2(0, -CELL.y - 40)
	add_child(water)

	zzz.add_theme_font_size_override("font_size", 28)
	zzz.position = Vector2(30, -CELL.y - 20)
	add_child(zzz)
	bubble.add_theme_font_size_override("font_size", 22)
	bubble.add_theme_color_override("font_outline_color", Color.BLACK)
	bubble.add_theme_constant_override("outline_size", 8)
	bubble.position = Vector2(-60, -CELL.y - 60)
	add_child(bubble)


func say(text: String) -> void:
	bubble.text = text
	await get_tree().create_timer(1.0).timeout
	if bubble.text == text:
		bubble.text = ""


func slap() -> void:
	flash = 1.0
	nod = maxf(0.0, nod - 0.25)


func set_showering(on: bool) -> void:
	showering = on
	water.emitting = on


func _process(delta: float) -> void:
	t += delta
	flash = maxf(0.0, flash - delta * 4.0)
	var droop := nod * deg_to_rad(38.0)
	var bob := sin(t * 2.2) * 0.05 * nod
	sprite.rotation = droop + bob
	sprite.position = Vector2(0, nod * 14.0)
	sprite.scale = Vector2(1.0, 1.0 - nod * 0.08)
	sprite.modulate = Color.WHITE.lerp(Color(1.6, 0.6, 0.6), flash)
	var frame := 0
	if flash > 0.25:
		frame = 4
	elif nod > 0.6:
		frame = 2
	elif showering:
		frame = int(t * 6.0) % 3
	sprite.region_rect = Rect2(frame * CELL.x, 0 if not showering else 4 * CELL.y, CELL.x, CELL.y)
	zzz.text = "Zzz" if nod > 0.5 else ""
