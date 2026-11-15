class_name Overlay
extends Node2D

var painter: Callable


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if painter.is_valid():
		painter.call(self)
