extends Entity

class_name Enemy

func _ready():
	add_to_group("enemy")
	add_to_group("maphost")
	set_collision_layer_bit(0, 0)
	set_collision_mask_bit(0, 0)
	set_collision_layer_bit(1, 1)
	set_collision_mask_bit(1, 1)

func check_for_death():
	if health <= 0:
		emit_signal("update_persistent_state")
		network.peer_call(self, "enemy_death", [global_position])
		enemy_death(global_position)

func enemy_death(pos):
	var death_animation = preload("res://effects/enemy_death.tscn").instance()
	death_animation.global_position = pos
	get_parent().add_child(death_animation)
	set_dead()

func set_health(value):
	health = value
	if health <= 0:
		set_dead()

remote func set_dead():
	hide()
	set_physics_process(false)
	home_position = Vector2(0,0)
	pos = Vector2(0,0)
	position = Vector2(0,0)
	health = -1

func is_dead():
	if health <= 0 && hitstun == 0:
		return true
	return false

func rand_direction():
	var new_direction = randi() % 4 + 1
	match new_direction:
		1:
			return Vector2.LEFT
		2:
			return Vector2.RIGHT
		3:
			return Vector2.UP
		4:
			return Vector2.DOWN
	return Vector2(0, 0)
