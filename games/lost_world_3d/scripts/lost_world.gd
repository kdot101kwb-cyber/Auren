extends Node3D

var checkpoint := 0
var health := 100
var stamina := 100.0
var objective_complete := false
var enemies_defeated := 0
var loot := 0
var combo := 0
var world_time := 0.0
var combo_timer := 0.0
var opened_chests := {}
var respawn_position := Vector3.ZERO
var save_path := "user://lost_world_checkpoint.save"
@onready var player: CharacterBody3D = $Player
@onready var combat: Node = $Player/Combat
@onready var vfx_audio: Node3D = $VFXAudio

func _ready() -> void:
	load_checkpoint()
	respawn_position = player.global_position
	build_world()
	spawn_encounters()
	update_hud()

func build_world() -> void:
	if get_node_or_null("Ground") == null:
		var floor_body := StaticBody3D.new()
		floor_body.name = "Ground"
		var collision := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = Vector3(80, 1, 180)
		collision.shape = shape
		floor_body.add_child(collision)
		floor_body.position = Vector3(0, -1, -80)
		add_child(floor_body)
	for i in range(20):
		var rock := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(2.0 + (i % 3), 1.2 + (i % 2), 2.0)
		rock.mesh = mesh
		rock.position = Vector3((i % 7) * 4.0 - 12.0, -0.4, -i * 5.0)
		add_child(rock)
	var gate := MeshInstance3D.new()
	var gate_mesh := BoxMesh.new()
	gate_mesh.size = Vector3(7, 6, 1)
	gate.mesh = gate_mesh
	gate.position = Vector3(0, 2, -75)
	add_child(gate)
	# Reward chests create a second reason to explore instead of only rushing the gate.
	for i in range(4):
		var chest := MeshInstance3D.new()
		chest.name = "RewardChest%d" % i
		var chest_mesh := BoxMesh.new()
		chest_mesh.size = Vector3(1.5, 0.9, 1.0)
		chest.mesh = chest_mesh
		chest.position = Vector3(-6 + i * 4.0, 0.45, -14 - i * 14.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.18,0.08,0.03)
		mat.metallic = 0.35
		mat.roughness = 0.45
		chest.material_override = mat
		chest.set_meta("loot_value", 25 + i * 10)
		chest.set_meta("opened", opened_chests.get(str(i), false))
		add_child(chest)

func spawn_encounters() -> void:
	for i in range(4):
		var enemy = get_node_or_null("Enemy" if i == 0 else "Enemy%d" % i)
		if enemy == null:
			var body := preload("res://scripts/enemy.gd")
			var e := CharacterBody3D.new()
			e.name = "Enemy%d" % i
			e.position = Vector3((i - 1.5) * 4.0, 0, -18.0 - i * 10.0)
			e.set_script(body)
			e.enemy_tint = Color(0.35 + i * 0.10, 0.10, 0.08 + i * 0.06)
			var shape := CollisionShape3D.new()
			var capsule := CapsuleShape3D.new()
			capsule.radius = 0.5
			capsule.height = 1.9
			shape.shape = capsule
			e.add_child(shape)
			add_child(e)

func _process(delta: float) -> void:
	world_time += delta
	if combo > 0:
		combo_timer -= delta
		if combo_timer <= 0.0:
			combo = 0
	update_hud()

func register_enemy_defeat() -> void:
	enemies_defeated += 1
	combo += 1
	loot += 10 + combo * 5
	combo_timer = 4.0
	vfx_audio.play_enemy_defeat_fx(player.global_position)
	if combo % 3 == 0:
		health = min(100, health + 10)
	update_hud()

func player_attack() -> void:
	if combat != null and combat.has_method("try_attack"):
		var hit = combat.try_attack(player)
		vfx_audio.play_attack_fx(player.global_position)
		if hit:
			vfx_audio.play_hit_fx(player.global_position)

func damage(amount: int) -> void:
	health = max(0, health - amount)
	if health == 0:
		load_checkpoint()
		player.global_position = respawn_position
		combo = 0
		combo_timer = 0.0
	update_hud()

func complete_objective() -> void:
	if objective_complete:
		return
	objective_complete = true
	checkpoint += 1
	save_checkpoint()
	vfx_audio.play_checkpoint_fx(player.global_position)
	update_hud()

func save_checkpoint() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_var({"checkpoint": checkpoint, "health": health, "objective_complete": objective_complete, "enemies_defeated": enemies_defeated, "loot": loot, "opened_chests": opened_chests})

func load_checkpoint() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f:
		var data = f.get_var()
		checkpoint = int(data.get("checkpoint", 0))
		health = int(data.get("health", 100))
		objective_complete = bool(data.get("objective_complete", false))
		enemies_defeated = int(data.get("enemies_defeated", 0))
		loot = int(data.get("loot", 0))
		opened_chests = data.get("opened_chests", {})

func update_hud() -> void:
	var status := get_node_or_null("HUD/Status")
	if status:
		status.text = "LOST WORLD  •  CP %d  •  HP %d  •  ENEMIES %d  •  LOOT %d  •  COMBO %d" % [checkpoint, health, enemies_defeated, loot, combo]
	var objective := get_node_or_null("HUD/Objective")
	if objective:
		objective.text = "Gate reached • Reward secured" if objective_complete else "Objective: Reach the ancient gate • Defeat enemies to earn loot"
