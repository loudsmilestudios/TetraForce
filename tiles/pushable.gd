extends StaticBody2D

signal on_done_moving

export(float) var time_for_effect: float = 1.0
export(bool) var is_one_shot: bool = false
export(Array) var direction_limits: Array

var has_been_pushed: bool = false
var time_being_pushed: float = 0.0
var is_moving: bool = false

onready var tween := $Tween
onready var ray := $RayCast2D
onready var destination := position

func _ready() -> void:
	set_physics_process(false)
	add_to_group("pushable")
	
	$Tween.connect("tween_completed", self, "_done_moving")
	# Ask for pushable state if needed (this must be deferred because the map_owners variable is 1 tick late after this _ready)
	call_deferred("_ask_coords")

func interact(node) -> void:
	if is_moving: # If the block is already moving, we can't interact anymore
		return
	
	time_being_pushed += get_physics_process_delta_time()
	
	# Activate the raycast if it's not active yet, and put it in the right direction
	if !ray.enabled:
		ray.enabled = true
		ray.cast_to = _get_direction(node.spritedir) * 8
	# If we have passed the time_for_effect treshold, initialize the move
	if time_being_pushed > time_for_effect:
		time_being_pushed = 0.0
		_prepare_move(node.spritedir)


# Player stopped interacting, reset the timer and ray
func stop_interact() -> void:
	time_being_pushed = 0.0
	ray.enabled = false


# Pushable has stopped moving (callback from tween_completed)
func _done_moving(node, key) -> void:
	is_moving = false
	
	emit_signal('on_done_moving') # Signal anyone who cares
	# If pushable is not a one shot, add it back to the pushable group
	if !is_one_shot:
		add_to_group("pushable")


# Prepare the movement
func _prepare_move(dir) -> void:
	var direction: Vector2 = _get_direction(dir)
	var is_colliding: bool = ray.is_colliding()
	
	ray.enabled = false # We can disable the raycast for now
	
	if is_colliding:
		return # Ray is colliding, can't move
	if direction_limits.size() != 0 && direction_limits.find(direction) == -1:
		return # Pushable has limited directions, and this is an invalid direction, can't move
	
	_do_move(direction)
	# Notify peers that pushable has started moving
	for peer in network.map_peers:
		rpc_id(peer, "_do_move", direction)


remote func _do_move(direction: Vector2) -> void:
	if is_moving: # someone else got here first
		return
	
	destination = position + direction * 16
	has_been_pushed = true
	is_moving = true
	ray.enabled = false
	time_being_pushed = 0.0
	
	remove_from_group("pushable")
	tween.interpolate_property(self, "position", position,destination, 1, Tween.TRANS_LINEAR, Tween.EASE_IN)
	tween.start()


# If we're not the map_owner, ask host for updated pushable state
func _ask_coords() -> void:
	var owner_id: int = network.map_owners[network.current_map.name]
	var own_id: int =  get_tree().get_network_unique_id()
	
	if own_id != owner_id:
		rpc_id(owner_id, "_get_state", own_id)


# Function called when peer requests pushable state
remote func _get_state(peer_id: int) -> void:
	# Only need to return the state if the object has been pushed, otherwise we can ignore this request
	if has_been_pushed:
		rpc_id(peer_id, "_update_state", destination)


# Function called when peer recieves updated pushable state
remote func _update_state(pos: Vector2) -> void:
	position = pos
	destination = pos
	has_been_pushed = true # we can infer this value from the fact that we only get a response if the block has been pushed
	
	# Signal anyone who cares, if we do this, then attached events are synced as well
	# and we don't need additional server requests to open doors for example (assuming they are controlled by this object)
	emit_signal('on_done_moving') 
	
	if is_one_shot: # de-activate pushable object if it's a one shot
		remove_from_group("pushable")


# Helper to get the normalized direction vector
func _get_direction(dir: String) -> Vector2:
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
