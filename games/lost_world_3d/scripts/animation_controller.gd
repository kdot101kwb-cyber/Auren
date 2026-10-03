extends Node3D
@export var player: CharacterBody3D
@onready var mesh: Node3D = get_parent().get_node_or_null("Mesh")
func _process(delta: float) -> void:
	if player == null or mesh == null: return
	var speed := Vector2(player.velocity.x, player.velocity.z).length()
	mesh.position.y = 0.9 + sin(Time.get_ticks_msec() * 0.012) * min(speed / 8.0, 1.0) * 0.035
	if speed > 0.1: mesh.rotation.y = lerp_angle(mesh.rotation.y, atan2(player.velocity.x, player.velocity.z), delta * 8.0)
