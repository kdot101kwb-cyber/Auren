extends CharacterBody3D

@export var speed := 5.5
@export var sprint_speed := 8.0
@export var jump_velocity := 6.5
var gravity := 18.0
var mobile_move := Vector2.ZERO
var mobile_look := Vector2.ZERO
var mobile_sprint := false

func _ready() -> void:
	var input = get_node_or_null("../MobileInput")
	if input:
		input.move_input.connect(_on_mobile_move)
		input.camera_input.connect(_on_mobile_look)
		input.jump_pressed.connect(_on_mobile_jump)
		input.attack_pressed.connect(_on_mobile_attack)
		input.interact_pressed.connect(_on_mobile_interact)
		input.sprint_pressed.connect(_on_mobile_sprint)

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	var input_vec := mobile_move if mobile_move.length() > 0.01 else Input.get_vector("move_left","move_right","move_forward","move_back")
	var direction := Vector3(input_vec.x,0,input_vec.y).normalized()
	var sprint := (Input.is_key_pressed(KEY_SHIFT) or mobile_sprint) and get_parent().stamina > 0.0
	var current_speed := sprint_speed if sprint else speed
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	if sprint:
		get_parent().stamina = max(0.0, get_parent().stamina - 28.0 * delta)
	else:
		get_parent().stamina = min(100.0, get_parent().stamina + 18.0 * delta)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if Input.is_action_just_pressed("interact"):
		interact()
	if Input.is_action_just_pressed("attack"):
		attack()
	move_and_slide()

func interact() -> void:
	var world = get_parent()
	if world.has_method("try_interact"):
		world.try_interact()

func attack() -> void:
	var world = get_parent()
	if world.has_method("player_attack"):
		world.player_attack()

func _on_mobile_move(value: Vector2) -> void:
	mobile_move = value

func _on_mobile_look(value: Vector2) -> void:
	mobile_look = value
	var rig = get_node_or_null("CameraRig")
	if rig:
		rig.rotation.y -= value.x * 0.015
		rig.rotation.x = clamp(rig.rotation.x - value.y * 0.01, -1.0, 0.35)

func _on_mobile_jump() -> void:
	if is_on_floor():
		velocity.y = jump_velocity

func _on_mobile_attack() -> void:
	attack()

func _on_mobile_interact() -> void:
	interact()

func _on_mobile_sprint(active: bool) -> void:
	mobile_sprint = active
