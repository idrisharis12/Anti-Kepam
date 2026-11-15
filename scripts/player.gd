extends Node2D

const CELL := Vector2(160, 142)
const SPEED := 150.0

var sprite := AnimatedSprite2D.new()
var bounds := Rect2(20, 60, 920, 460)


func _ready() -> void:
	var sheet: Texture2D = load("res://assets/boy_sheet.png")
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	_add_anim(frames, "idle", sheet, 0, [0, 1, 2], 3.0)
	_add_anim(frames, "scratch", sheet, 0, [3, 4, 5, 6], 6.0)
	_add_anim(frames, "down", sheet, 1, [0, 1], 5.0)
	_add_anim(frames, "side", sheet, 1, [2, 3, 4, 5, 6, 7], 9.0)
	_add_anim(frames, "up", sheet, 2, [0, 1, 2, 3, 4, 5, 6, 7], 9.0)
	sprite.sprite_frames = frames
	sprite.scale = Vector2(0.38, 0.38)
	add_child(sprite)
	sprite.play("idle")


func _add_anim(frames: SpriteFrames, anim: String, sheet: Texture2D, row: int, cols: Array, fps: float) -> void:
	frames.add_animation(anim)
	frames.set_animation_speed(anim, fps)
	frames.set_animation_loop(anim, true)
	for c in cols:
		var at := AtlasTexture.new()
		at.atlas = sheet
		at.region = Rect2(c * CELL.x, row * CELL.y, CELL.x, CELL.y)
		frames.add_frame(anim, at)


var foot_t := 0.0


func _process(delta: float) -> void:
	var v := GameState.move_vec()
	if v == Vector2.ZERO:
		if sprite.animation not in ["idle", "scratch"]:
			sprite.play("idle")
		return
	foot_t -= delta
	if foot_t <= 0.0:
		foot_t = 0.32
		Sfx.footstep()
	position += v * SPEED * delta
	position = position.clamp(bounds.position, bounds.end)
	if absf(v.x) > absf(v.y):
		sprite.flip_h = v.x < 0
		sprite.play("side")
	elif v.y < 0:
		sprite.flip_h = false
		sprite.play("up")
	else:
		sprite.flip_h = false
		sprite.play("down")
