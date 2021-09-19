extends KinematicBody2D

onready var ray = $RayCast2D
onready var tween = $Tween

onready var target_position = position setget set_block_position
onready var pushed = false setget set_pushed
onready var home_position = position

func _ready():
	add_to_group("pushable")
	add_to_group("objects")
	set_collision_layer_bit(10, 1)
	print(target_position)
	
func interact(node):
	if tween.is_active():
		return
	if network.is_map_host():
		attempt_move(node.last_movedir)
	else:
		network.peer_call_id(network.get_map_host(), self, "attempt_move", [node.last_movedir])

func attempt_move(direction):
	ray.cast_to = direction * 16
	yield(get_tree().create_timer(0.05), "timeout")
	if !ray.is_colliding() && !pushed && is_network_master():
		process_move_attempt(direction)
	if ray.is_colliding() && ray.get_collider().has_method("clear_water"):
		if is_network_master():
			process_move_attempt(direction)
			ray.get_collider().clear_water(target_position)

func set_block_position(value):
	target_position = value
	snap_to(position, target_position)

func set_pushed(value):
	pushed = value
	if pushed:
		yield(get_tree().create_timer(0.5), "timeout")
		$AnimationPlayer.play("sink")
		yield($AnimationPlayer, "animation_finished")
		$AnimationPlayer.play("floating")

func move_to(current_pos, target_pos):
	tween.interpolate_property(self, "position", current_pos, target_pos, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	sfx.play("push")

func snap_to(current_pos, target_pos):
	tween.interpolate_property(self, "position", current_pos, target_pos, 0.1, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
	
func set_default_state():
	set_pushed(false)
	target_position = home_position
	snap_to(target_position, home_position)
	
func process_move_attempt(direction):
	target_position = (position + direction * 16).snapped(Vector2(16,16)) - Vector2(8,8)
	set_pushed(true)
	move_to(position, target_position)
	network.peer_call(self, "move_to", [position, target_position])
	network.peer_call(self, "set_pushed", [pushed])

