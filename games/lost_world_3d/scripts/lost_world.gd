extends Node3D

var checkpoint := 0
var health := 100
var stamina := 100.0
var objective_complete := false
var save_path := "user://lost_world_checkpoint.save"
@onready var player: CharacterBody3D = $Player
@onready var combat: Node = $Player/Combat

func _ready() -> void:
	load_checkpoint()
	build_world()
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

func player_attack() -> void:
	if combat != null and combat.has_method("try_attack"):
		combat.try_attack(player)

func damage(amount: int) -> void:
	health = max(0, health - amount)
	if health == 0:
		load_checkpoint()
		player.global_position = Vector3.ZERO
	update_hud()

func complete_objective() -> void:
	if objective_complete:
		return
	objective_complete = true
	checkpoint += 1
	save_checkpoint()
	update_hud()

func save_checkpoint() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	if f:
		f.store_var({"checkpoint": checkpoint, "health": health, "objective_complete": objective_complete})

func load_checkpoint() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	if f:
		var data = f.get_var()
		checkpoint = int(data.get("checkpoint", 0))
		health = int(data.get("health", 100))
		objective_complete = bool(data.get("objective_complete", false))

func update_hud() -> void:
	var status := get_node_or_null("HUD/Status")
	if status:
		status.text = "LOST WORLD  •  CHECKPOINT %d  •  HP %d" % [checkpoint, health]
	var objective := get_node_or_null("HUD/Objective")
	if objective:
		objective.text = "Objective: Gate reached" if objective_complete else "Objective: Reach the ancient gate"
