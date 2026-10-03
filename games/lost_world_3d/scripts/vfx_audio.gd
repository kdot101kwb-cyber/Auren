extends Node3D

var audio_player: AudioStreamPlayer3D
var active_fx := 0
var max_active_fx := 120

func _ready() -> void:
	if OS.has_feature("mobile"):
		max_active_fx = 72
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "SpatialAudio"
	audio_player.max_distance = 45.0
	audio_player.unit_size = 3.0
	add_child(audio_player)

func play_attack_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 22, 0.22, 2.0, 6.0, Color(0.55,0.35,1.0), 0.06)
	_spawn_ring(origin, Color(0.72,0.45,1.0), 0.35, 1.25)

func play_hit_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 30, 0.30, 2.0, 8.0, Color(1.0,0.35,0.12), 0.075)
	_spawn_ring(origin, Color(1.0,0.4,0.12), 0.25, 0.9)

func play_checkpoint_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 55, 1.0, 1.0, 4.0, Color(0.2,0.8,1.0), 0.11)
	_spawn_ring(origin, Color(0.2,0.9,1.0), 0.6, 2.6)

func play_loot_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 32, 0.65, 1.0, 3.5, Color(1.0,0.78,0.18), 0.055)
	_spawn_ring(origin, Color(1.0,0.82,0.2), 0.45, 1.8)

func play_player_death_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 46, 0.7, 1.5, 5.0, Color(0.65,0.08,0.55), 0.07)
	_spawn_ring(origin, Color(0.85,0.12,0.65), 0.35, 2.0)
	_spawn_death_flash(origin)

func _spawn_death_flash(origin: Vector3) -> void:
	if active_fx >= max_active_fx:
		return
	active_fx += 1
	var flash := OmniLight3D.new()
	flash.position = origin + Vector3.UP * 0.9
	flash.light_energy = 4.0
	flash.omni_range = 5.0
	flash.light_color = Color(0.8, 0.12, 0.65)
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "light_energy", 0.0, 0.32).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_finish_fx.bind(flash))

func play_enemy_defeat_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 38, 0.55, 1.5, 5.5, Color(0.9,0.12,0.08), 0.065)
	_spawn_ring(origin, Color(1.0,0.18,0.08), 0.5, 1.7)

func _spawn_ring(origin: Vector3, tint: Color, start_radius: float, end_radius: float) -> void:
	if active_fx >= max_active_fx:
		return
	active_fx += 1
	origin.y += 0.04
	var ring := MeshInstance3D.new()
	var mesh := TorusMesh.new()
	mesh.inner_radius = 0.72
	mesh.outer_radius = 0.86
	ring.mesh = mesh
	ring.position = origin
	ring.scale = Vector3(start_radius, 0.04, start_radius)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 2.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color.a = 0.9
	ring.material_override = mat
	add_child(ring)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(ring, "scale", Vector3(end_radius, 0.04, end_radius), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(mat, "albedo_color:a", 0.0, 0.28)
	tween.chain().tween_callback(_finish_fx.bind(ring))

func _spawn_burst(origin: Vector3, count: int, life: float, min_speed: float, max_speed: float, tint: Color, size: float) -> void:
	if active_fx >= max_active_fx:
		return
	active_fx += 1
	var burst := GPUParticles3D.new()
	burst.amount = count
	burst.lifetime = life
	burst.one_shot = true
	burst.position = origin
	var process := ParticleProcessMaterial.new()
	process.spread = 180.0
	process.initial_velocity_min = min_speed
	process.initial_velocity_max = max_speed
	process.gravity = Vector3(0, -3, 0)
	process.color = tint
	burst.process_material = process
	var mesh := SphereMesh.new()
	mesh.radius = size
	mesh.height = size * 2.0
	burst.draw_pass_1 = mesh
	add_child(burst)
	burst.emitting = true
	await get_tree().create_timer(life + 0.15).timeout
	if is_instance_valid(burst):
		_finish_fx(burst)

func _finish_fx(node: Node) -> void:
	if is_instance_valid(node):
		node.queue_free()
	active_fx = max(0, active_fx - 1)
