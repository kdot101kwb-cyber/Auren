extends CanvasLayer

signal move_input(value: Vector2)
signal camera_input(value: Vector2)
signal jump_pressed
signal attack_pressed
signal interact_pressed

var move_touch := -1
var look_touch := -1
var move_start := Vector2.ZERO
var look_start := Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			if event.position.x < get_viewport().size.x * 0.45:
				move_touch = event.index
				move_start = event.position
			else:
				look_touch = event.index
				look_start = event.position
		else:
			if event.index == move_touch:
				move_touch = -1
				move_input.emit(Vector2.ZERO)
			if event.index == look_touch:
				look_touch = -1
				camera_input.emit(Vector2.ZERO)
	elif event is InputEventScreenDrag:
		if event.index == move_touch:
			var delta := (event.position - move_start) / 110.0
			move_input.emit(delta.limit_length(1.0))
		elif event.index == look_touch:
			camera_input.emit((event.position - look_start) / 120.0)
			look_start = event.position
