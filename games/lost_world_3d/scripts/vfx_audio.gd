extends Node3D

var audio_player: AudioStreamPlayer3D

func _ready() -> void:
	audio_player = AudioStreamPlayer3D.new()
	audio_player.name = "SpatialAudio"
	add_child(audio_player)

func play_attack_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 18, 0.22, 2.0, 5.0)

func play_hit_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 24, 0.30, 2.0, 7.0)

func play_checkpoint_fx(origin: Vector3) -> void:
	_spawn_burst(origin, 40, 1.0, 1.0, 3.0)

func _spawn_burst(origin: Vector3, count: int, life: float, min_speed: float, max_speed: float) -> void:
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
	burst.process_material = process
	var mesh := SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	burst.draw_pass_1 = mesh
	add_child(burst)
	burst.emitting = true
	await get_tree().create_timer(life + 0.15).timeout
	burst.queue_free()
