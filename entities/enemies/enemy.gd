extends Entity

class_name Enemy

@export var chest_spawn: bool = false
@export var location: String = "room"
@export var spawned_by: String = ""

var spawn_position = home_position
var disabled_collision_shapes = {}

func _ready():
	super()
	spawn_position = home_position
	add_to_group("enemy")
	add_to_group("maphost")
	# Keep player-only obstacles (e.g. signs) out of enemy motion. Solid
	# scenery that blocked enemies via its mask in Godot 3 now also belongs
	# to ACTOR, so the enemy's own movement mask can detect it in Godot 4.
	set_collision_layer_value(1, 0)
	set_collision_mask_value(1, 0)
	set_collision_layer_value(2, 1)
	set_collision_mask_value(2, 1)
	collision_layer |= CollisionLayers.ENEMY_BODY
	set_hole_bit(hitstun == 0)
	var player_detect = get_node_or_null("PlayerDetect")
	if player_detect is Area2D:
		player_detect.collision_mask = 1 << 1
	if spawned_by != "":
		set_dead()
		map.get_node(spawned_by).connect("started", Callable(self, "spawned"))
		map.get_node(spawned_by).connect("check_for_active", Callable(self, "spawned"))
		map.get_node(spawned_by).connect("reset", Callable(self, "set_dead"))

func _process(delta):
	super(delta)
	set_hole_bit(hitstun == 0)

func set_hole_bit(bit):
	set_collision_layer_value(8, bit)
	set_collision_mask_value(8, bit)

func check_for_death():
	if health <= 0:
		emit_signal("update_persistent_state")
		network.peer_call(self, "enemy_death", [global_position])
		enemy_death(global_position)

func enemy_death(pos):
	var death_animation = preload("res://effects/enemy_death.tscn").instantiate()
	death_animation.global_position = pos
	map.add_child(death_animation)
	sfx.play("enemy_death")
	if chest_spawn == true:
		var spawn_node = location #Sets Spawn Node Name
		var spawn_point = map.get_node(spawn_node) #Get Spawn Node
		spawn_point.chest_spawn()
	else:
		network.current_map.spawn_collectable("tetran", pos, 4)
		
	set_dead()

func set_health(value):
	super(value)
	if value <= 0:
		set_dead()

func hole_fall():
	set_dead()
	network.peer_call(self, "set_dead")

@rpc("any_peer") func set_dead():
	hide()
	set_physics_process(false)
	set_collision_shapes_disabled(true)
	home_position = Vector2(0,0)
	_pos = Vector2(0,0)
	position = Vector2(0,0)
	super.set_health(-1)
	
func spawned():
	if network.is_map_host():
		network.peer_call(self, "spawned")
	show()
	set_physics_process(true)
	set_collision_shapes_disabled(false)
	home_position = spawn_position
	_pos = home_position
	position = home_position
	_health = MAX_HEALTH
	var death_animation = preload("res://effects/enemy_death.tscn").instantiate()
	death_animation.global_position = position
	map.add_child(death_animation)

func set_collision_shapes_disabled(disabled):
	if disabled:
		if !disabled_collision_shapes.is_empty():
			return
		for shape in find_children("*", "", true, false):
			if shape is CollisionShape2D or shape is CollisionPolygon2D:
				disabled_collision_shapes[shape] = shape.disabled
				shape.set_deferred("disabled", true)
	else:
		for shape in disabled_collision_shapes:
			if is_instance_valid(shape):
				shape.set_deferred("disabled", disabled_collision_shapes[shape])
		disabled_collision_shapes.clear()

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

#Elimates scenarios where an enemy with a detection shape changing direction doesn't do so unfairly.
func rand_direction_fair(prev_direction : Vector2):
	var new_direction
	if prev_direction == Vector2.LEFT:
		new_direction = randi() % 2 + 1
		match new_direction:
			1:
				return Vector2.DOWN
			2:
				return Vector2.UP
	elif prev_direction == Vector2.UP:
		new_direction = randi() % 2 + 1
		match new_direction:
			1:
				return Vector2.LEFT
			2:
				return Vector2.RIGHT
	elif prev_direction == Vector2.RIGHT:
		new_direction = randi() % 2 + 1
		match new_direction:
			1:
				return Vector2.DOWN
			2:
				return Vector2.UP
	else:
		new_direction = randi() % 2 + 1
		match new_direction:
			1:
				return Vector2.LEFT
			2:
				return Vector2.RIGHT
