extends Node
var frames := 0
var elapsed := 0.0
var worst_ms := 0.0
func _process(delta: float) -> void:
	frames += 1
	elapsed += delta
	worst_ms = max(worst_ms, delta * 1000.0)
	if elapsed >= 5.0:
		print("AUREN_PERF fps=%.1f worst_ms=%.1f memory_mb=%.1f" % [frames / elapsed, worst_ms, OS.get_static_memory_usage() / 1048576.0])
		frames = 0
		elapsed = 0.0
		worst_ms = 0.0
