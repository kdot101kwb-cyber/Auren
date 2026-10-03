extends Node3D

var checkpoint := 0
var health := 100
var stamina := 100
var objective_complete := false
var save_path := "user://lost_world_checkpoint.save"

func _ready() -> void:
	load_checkpoint()
	build_world()

func build_world() -> void:
	for i in range(14):
		var rock := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(2.0 + (i % 3), 1.2 + (i % 2), 2.0)
		rock.mesh = mesh
		rock.position = Vector3((i % 7) * 4.0 - 12.0, -0.6, -i * 5.0)
		add_child(rock)
	var gate := MeshInstance3D.new()
	var gate_mesh := BoxMesh.new()
	gate_mesh.size = Vector3(7,6,1)
	gate.mesh = gate_mesh
	gate.position = Vector3(0,3,-75)
	add_child(gate)

func damage(amount: int) -> void:
	health = max(0, health - amount)
	if health == 0:
		load_checkpoint()
	queue_redraw()

func complete_objective() -> void:
	objective_complete = true
	checkpoint += 1
	save_checkpoint()

func save_checkpoint() -> void:
	var f := FileAccess.open(save_path, FileAccess.WRITE)
	f.store_var({"checkpoint":checkpoint,"health":health,"objective_complete":objective_complete})

func load_checkpoint() -> void:
	if not FileAccess.file_exists(save_path):
		return
	var f := FileAccess.open(save_path, FileAccess.READ)
	var data = f.get_var()
	checkpoint = int(data.get("checkpoint",0))
	health = int(data.get("health",100))
	objective_complete = bool(data.get("objective_complete",false))
