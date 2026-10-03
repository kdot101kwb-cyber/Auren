extends CharacterBody3D

@export var speed := 2.8
@export var detection_range := 18.0
@export var max_health := 100
@export var enemy_tint := Color(0.55,0.12,0.08)
var health := 100
var attack_timer := 0.0

func _ready() -> void:
	health = max_health
	_build_visual()

func _build_visual() -> void:
	if get_node_or_null("Mesh") != null:
		return
	var mesh_node := MeshInstance3D.new()
	mesh_node.name = "Mesh"
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.52
	mesh.height = 1.9
	mesh_node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = enemy_tint
	mat.metallic = 0.05
	mat.roughness = 0.82
	mesh_node.material_override = mat
	add_child(mesh_node)
	var eye := MeshInstance3D.new()
	eye.name = "EyeGlow"
	var eye_mesh := SphereMesh.new()
	eye_mesh.radius = 0.09
	eye_mesh.height = 0.18
	eye.mesh = eye_mesh
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0,0.72,0.18)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0,0.22,0.05)
	eye_mat.emission_energy_multiplier = 3.0
	eye.material_override = eye_mat
	eye.position = Vector3(0,0.48, -0.46)
	add_child(eye)

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	if health == 0:
		var world = get_parent()
		if world.has_method("register_enemy_defeat"):
			world.register_enemy_defeat()
		queue_free()

func _physics_process(delta: float) -> void:
	var player := get_parent().get_node_or_null("Player")
	if player == null:
		return
	var distance := global_position.distance_to(player.global_position)
	if distance <= detection_range:
		var direction := player.global_position - global_position
		direction.y = 0
		if direction.length() > 2.4:
			velocity = direction.normalized() * speed
		else:
			velocity = Vector3.ZERO
			attack_timer -= delta
			if attack_timer <= 0:
				if player.get_parent().has_method("damage"):
					player.get_parent().damage(8)
				attack_timer = 1.2
	else:
		velocity = Vector3.ZERO
	move_and_slide()
