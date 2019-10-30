extends StaticBody2D


export(float) var time_for_effect = 1.0
export(bool) var is_one_shot = false
export(Array) var direction_limits


var has_been_pushed = false
var time_being_pushed = 0.0
var is_moving = false


onready var tween := $Tween
onready var ray := $RayCast2D
onready var original_position := position
onready var destination := position


func _ready():
	set_physics_process(false)
	add_to_group("pushable")
	
	$Tween.connect("tween_completed", self, "_done_moving")
	call_deferred("_ask_coords")


func interact(node):
	if is_moving:
		return
	
	time_being_pushed += get_physics_process_delta_time()
	
	if !ray.enabled:
		ray.enabled = true
		ray.cast_to = _get_direction(node.spritedir) * 8
	if time_being_pushed > time_for_effect:
		time_being_pushed = 0.0
		_initialise_move(node.spritedir)


func stop_interact():
	time_being_pushed = 0.0
	ray.enabled = false


func _done_moving(node, key) -> void:
	is_moving = false
	
	if !is_one_shot:
		add_to_group("pushable")


func _initialise_move(dir):
	var direction = _get_direction(dir)
	var is_colliding = ray.is_colliding()
	
	ray.enabled = false
	
	if is_colliding:
		return
	if direction_limits.size() != 0 && direction_limits.find(direction) == -1:
		return
	
	_do_move(direction)
	for peer in network.map_peers:
		rpc_id(peer, "_do_move", direction)


func _get_direction(dir):
	match dir:
		"Up":
			return Vector2.UP
		"Down":
			return Vector2.DOWN
		"Left":
			return Vector2.LEFT
		"Right":
			return Vector2.RIGHT
		_:
			return Vector2.ZERO


func _ask_coords():
	var owner_id = network.map_owners[network.current_map.name]
	var own_id =  get_tree().get_network_unique_id()
	
	if own_id != owner_id:
		rpc_id(owner_id, "_get_state", own_id)


remote func _do_move(direction):
	if is_moving: # someone else got here first
		return
	
	destination = position + direction * 16
	has_been_pushed = true
	is_moving = true
	ray.enabled = false
	time_being_pushed = 0.0
	
	remove_from_group("pushable")
	tween.interpolate_property(self,"position",position,destination,1,Tween.TRANS_LINEAR,Tween.EASE_IN)
	tween.start()


remote func _get_state(peer_id):
	# Only need to return the state if the object has been pushed
	if has_been_pushed:
		rpc_id(peer_id, "_update_state", destination)


remote func _update_state(pos):
	position = pos
	has_been_pushed = true # we can infer this value from the fact that we only get a response if the block has been pushed
	if is_one_shot: # de-activate pushable object if it's a one shot
		remove_from_group("pushable")
	
