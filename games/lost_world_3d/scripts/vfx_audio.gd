extends Node3D

var audio_player: AudioStreamPlayer3D

func _ready() -> void:
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "SpatialAudio"
	audio_player.max_distance = 45.0
	audio_player.unit_size = 3.0
	add_child(audio_player)

func play_attack_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 22, 0.22, 2.0, 6.0, Color(0.55,0.35,1.0), 0.06)

func play_hit_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 30, 0.30, 2.0, 8.0, Color(1.0,0.35,0.12), 0.075)

func play_checkpoint_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 55, 1.0, 1.0, 4.0, Color(0.2,0.8,1.0), 0.11)

func play_loot_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 32, 0.65, 1.0, 3.5, Color(1.0,0.78,0.18), 0.055)

func play_enemy_defeat_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 38, 0.55, 1.5, 5.5, Color(0.9,0.12,0.08), 0.065)

func _spawn_burst(origin: Vector3, count: int, life: float, min_speed: float, max_speed: float, tint: Color, size: float) -> void:
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
		burst.queue_free()
