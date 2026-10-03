extends DirectionalLight3D
@export var cycle_seconds := 300.0
var elapsed := 0.0
func _process(delta: float) -> void:
	elapsed = fmod(elapsed + delta, cycle_seconds)
	var phase := elapsed / cycle_seconds
	rotation_degrees.x = lerp(-25.0, -155.0, phase)
	light_energy = 0.25 + 0.95 * max(0.0, sin(phase * PI))
