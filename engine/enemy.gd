extends Entity

class_name Enemy

func _ready():
	add_to_group("enemy")
	add_to_group("maphost")
	set_collision_layer_bit(0, 0)
	set_collision_mask_bit(0, 0)
	set_collision_layer_bit(1, 1)
	set_collision_mask_bit(1, 1)
	
	connect("hitstun_end", self, "check_for_death")
	#network.current_map.connect("player_entered", self, "player_entered")

func check_for_death():
	if health <= 0:
		network.peer_call(self, "enemy_death")
		enemy_death()

remote func enemy_death():
	var death_animation = preload("res://enemies/enemy_death.tscn").instance()
	death_animation.global_position = global_position
	get_parent().add_child(death_animation)
	set_dead()

remote func set_dead():
	hide()
	set_physics_process(false)
	home_position = Vector2(0,0)
	position = Vector2(0,0)
	health = -1

func player_entered(id):
	if id == get_tree().get_network_unique_id() || !network.is_map_host():
		return
	#print(str(self, " recognizes player entry of ", id))
	network.peer_call_id(id, self, "set_health", [health])
	if health <= 0:
		network.peer_call_id(id, self, "set_dead")

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
