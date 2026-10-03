extends CanvasLayer

signal move_input(value: Vector2)
signal camera_input(value: Vector2)
signal jump_pressed
signal attack_pressed
signal interact_pressed
signal sprint_pressed(active: bool)
signal dodge_pressed
var sprint_active := false

var move_touch := -1
var look_touch := -1
var move_start := Vector2.ZERO
var look_start := Vector2.ZERO
var action_root: Control

func _ready() -> void:
	_build_action_buttons()

func _build_action_buttons() -> void:
	action_root = Control.new()
	action_root.name = "ActionButtons"
	action_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	action_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(action_root)
	for spec in [
		{"name":"Attack","text":"⚔","pos":Vector2(0.80,0.72),"signal":"attack"},
		{"name":"Jump","text":"↑","pos":Vector2(0.68,0.78),"signal":"jump"},
		{"name":"Interact","text":"E","pos":Vector2(0.84,0.58),"signal":"interact"},
		{"name":"Sprint","text":"RUN","pos":Vector2(0.56,0.86),"signal":"sprint"},
		{"name":"Dodge","text":"DASH","pos":Vector2(0.69,0.63),"signal":"dodge"}
	]:
		var b := Button.new()
		b.name = spec.name
		b.text = spec.text
		b.position = Vector2(get_viewport().size.x * spec.pos.x, get_viewport().size.y * spec.pos.y)
		b.size = Vector2(76,76)
		b.modulate.a = 0.78
		b.mouse_filter = Control.MOUSE_FILTER_STOP
		action_root.add_child(b)
		match spec.signal:
			"attack": b.pressed.connect(func(): attack_pressed.emit())
			"jump": b.pressed.connect(func(): jump_pressed.emit())
			"interact": b.pressed.connect(func(): interact_pressed.emit())
			"sprint":
				b.button_down.connect(func(): sprint_active = true; sprint_pressed.emit(true))
				b.button_up.connect(func(): sprint_active = false; sprint_pressed.emit(false))
			"dodge": b.pressed.connect(func(): dodge_pressed.emit())

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and action_root != null:
		_layout_buttons()

func _layout_buttons() -> void:
	for b in action_root.get_children():
		var pos := Vector2.ZERO
		match b.name:
			"Attack": pos = Vector2(0.80,0.72)
			"Jump": pos = Vector2(0.68,0.78)
			"Interact": pos = Vector2(0.84,0.58)
			"Sprint": pos = Vector2(0.56,0.86)
			"Dodge": pos = Vector2(0.69,0.63)
		b.position = Vector2(get_viewport().size.x * pos.x, get_viewport().size.y * pos.y)

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
