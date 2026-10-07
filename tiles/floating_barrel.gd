extends CharacterBody2D

@onready var ray = $RayCast2D
var tween: Tween
var motion := PushMotion.new()
var sink_generation := 0

@onready var _target_position = position
var target_position:
	get:
		return _target_position
	set(value):
		set_block_position(value)
@onready var pushed = false: set = set_pushed
@onready var home_position = position

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	add_to_group("pushable")
	add_to_group("objects")
	set_collision_layer_value(11, 1)
	
func interact(node):
	if motion.is_busy():
		return
	var direction = node.get_push_direction() if node.has_method("get_push_direction") else node.last_movedir
	if network.is_map_host():
		attempt_move(direction)
	else:
		network.peer_call_id(network.get_map_host(), self, "attempt_move", [direction])

func attempt_move(direction):
	if !pushed:
		var ticket := motion.reserve(direction)
		if ticket < 0:
			return
		ray.target_position = direction * 16
		await get_tree().create_timer(0.05).timeout
		if !motion.resolve(ticket):
			return
		ray.force_raycast_update()
		var collider = ray.get_collider()
		if !ray.is_colliding() && !pushed && is_multiplayer_authority():
			process_move_attempt(direction)
		if is_instance_valid(collider) && collider.has_method("clear_water"):
			if is_multiplayer_authority():
				process_move_attempt(direction)
				collider.clear_water(get_parent().to_global(target_position))
				set_pushed(true)
				network.peer_call(self, "set_pushed", [pushed])

func set_block_position(value):
	_target_position = value
	snap_to(position, _target_position)

func set_pushed(value):
	sink_generation += 1
	var ticket := sink_generation
	pushed = value
	if pushed:
		await get_tree().create_timer(0.5).timeout
		# Resetting the room must invalidate this delayed animation just as it
		# invalidates pending pushes and active movement tweens.
		if ticket != sink_generation or !pushed:
			return
		$AnimationPlayer.play("sink")
	else:
		$AnimationPlayer.play("default")

func move_to(current_pos, target_pos):
	tween = motion.animate(self, current_pos, target_pos, 1.0)
	sfx.play("push")

func snap_to(current_pos, target_pos):
	tween = motion.animate(self, current_pos, target_pos, 0.1)
	
func set_default_state(action_zone=null):
	motion.cancel()
	_target_position = home_position
	position = home_position
	set_pushed(false)
	
func process_move_attempt(direction):
	_target_position = (position + direction * 16).snapped(Vector2(16,16)) - Vector2(8,8)
	move_to(position, _target_position)
	network.peer_call(self, "move_to", [position, _target_position])
	
