extends CharacterBody3D

@export var speed := 5.5
@export var sprint_speed := 8.0
@export var jump_velocity := 6.5
var gravity := 18.0
var stamina := 100.0
var attack_cooldown := 0.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	var input_vec := Input.get_vector("move_left","move_right","move_forward","move_back")
	var direction := Vector3(input_vec.x,0,input_vec.y).normalized()
	var sprint := Input.is_key_pressed(KEY_SHIFT) and stamina > 0.0
	var current_speed := sprint_speed if sprint else speed
	velocity.x = direction.x * current_speed
	velocity.z = direction.z * current_speed
	if sprint:
		stamina = max(0.0, stamina - 28.0 * delta)
	else:
		stamina = min(100.0, stamina + 18.0 * delta)
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if Input.is_action_just_pressed("interact"):
		var world = get_parent()
		if world.has_method("complete_objective") and global_position.z < -65:
			world.complete_objective()
	move_and_slide()
