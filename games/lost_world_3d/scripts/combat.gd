extends Node

@export var damage := 25
@export var attack_range := 3.0
@export var cooldown := 0.65
var timer := 0.0
var combo_hits := 0

func _process(delta: float) -> void:
	timer = max(0.0, timer - delta)

func try_attack(owner: Node3D) -> bool:
	if timer > 0.0:
		return false
	timer = cooldown
	combo_hits += 1
	var state := owner.get_world_3d().direct_space_state
	var from := owner.global_position + Vector3.UP * 1.0
	var to := from + -owner.global_transform.basis.z * attack_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [owner]
	var hit := state.intersect_ray(query)
	if not hit.is_empty():
		var target = hit.get("collider")
		if target != null and target.has_method("take_damage"):
			target.take_damage(damage)
			return true
	return false
