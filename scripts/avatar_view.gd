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
var dirt := 0.0
var smoke := CPUParticles2D.new()


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

	smoke.emitting = false
	smoke.amount = 40
	smoke.lifetime = 1.8
	smoke.direction = Vector2(0, -1)
	smoke.spread = 35.0
	smoke.gravity = Vector2(0, -25)
	smoke.initial_velocity_min = 12.0
	smoke.initial_velocity_max = 34.0
	smoke.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	smoke.emission_rect_extents = Vector2(34, 46)
	smoke.scale_amount_min = 0.5
	smoke.scale_amount_max = 1.1
	smoke.color = Color(0.45, 0.9, 0.15, 0.55)
	smoke.position = Vector2(0, -CELL.y * 0.5)
	smoke.z_index = 2
	smoke.local_coords = true
	var gt := GradientTexture2D.new()
	gt.fill = GradientTexture2D.FILL_RADIAL
	gt.fill_from = Vector2(0.5, 0.5)
	gt.fill_to = Vector2(1.0, 0.5)
	gt.width = 32
	gt.height = 32
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 0.9))
	gr.set_color(1, Color(1, 1, 1, 0.0))
	gt.gradient = gr
	smoke.texture = gt
	add_child(smoke)

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
	sprite.modulate = Color.WHITE.lerp(Color(0.62, 0.78, 0.38), dirt * 0.65).lerp(Color(1.6, 0.6, 0.6), flash)
	smoke.emitting = dirt > 0.04
	smoke.speed_scale = 0.8 + dirt
	queue_redraw()
	var frame := 0
	if flash > 0.25:
		frame = 4
	elif nod > 0.6:
		frame = 2
	elif showering:
		frame = int(t * 6.0) % 3
	sprite.region_rect = Rect2(frame * CELL.x, 0 if not showering else 4 * CELL.y, CELL.x, CELL.y)
	zzz.text = "Zzz" if nod > 0.5 else ""


func _draw() -> void:
	if dirt <= 0.04:
		return
	draw_set_transform(sprite.position, sprite.rotation, sprite.scale)
	var head := Vector2(0, -CELL.y * 0.66)
	var n := int(3 + dirt * 9.0)
	for i in n:
		var a := -PI * 0.5 + (i - n * 0.5) * 0.28
		var d := Vector2(cos(a), sin(a))
		var wob := sin(t * 5.0 + i * 1.9) * 4.0
		var p0 := head + Vector2((i - n * 0.5) * 3.0, 4.0)
		var p1 := p0 + d * (14.0 + dirt * 12.0) + Vector2(wob, 0)
		var p2 := p1 + Vector2(wob * 0.9 + (i % 3 - 1) * 6.0, -8.0 - dirt * 7.0)
		draw_polyline(PackedVector2Array([p0, p1, p2]), Color(0.16, 0.08, 0.04), 2.6)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	for i in int(dirt * 5.0):
		var ph := fmod(t * 0.7 + i * 0.37, 1.0)
		var x := (i - 2) * 14.0 + sin(t * 3.0 + i) * 6.0
		var pts := PackedVector2Array()
		for k in 5:
			pts.append(Vector2(x + sin(ph * 6.0 + k) * 5.0, -30.0 - ph * 80.0 - k * 9.0))
		draw_polyline(pts, Color(0.5, 0.9, 0.2, 0.55 * (1.0 - ph)), 3.0)
