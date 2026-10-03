extends CharacterBody3D

@export var speed := 2.8
@export var detection_range := 18.0
@export var max_health := 100
var health := 100
var attack_timer := 0.0

func _ready() -> void:
	health = max_health

func take_damage(amount: int) -> void:
	health = max(0, health - amount)
	if health == 0:
		var world = get_parent()
		if world.has_method("register_enemy_defeat"):
			world.register_enemy_defeat()
		queue_free()

func _physics_process(delta: float) -> void:
	var player := get_parent().get_node_or_null("Player")
	if player == null:
		return
	var distance := global_position.distance_to(player.global_position)
	if distance <= detection_range:
		var direction := player.global_position - global_position
		direction.y = 0
		if direction.length() > 2.4:
			velocity = direction.normalized() * speed
		else:
			velocity = Vector3.ZERO
			attack_timer -= delta
			if attack_timer <= 0:
				if player.get_parent().has_method("damage"):
					player.get_parent().damage(8)
				attack_timer = 1.2
	else:
		velocity = Vector3.ZERO
	move_and_slide()
