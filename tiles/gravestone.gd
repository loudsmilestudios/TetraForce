extends StaticBody2D

@onready var ray = $RayCast2D
var tween: Tween
var motion := PushMotion.new()
var pushing_player
var player_was_processing := false

@onready var _target_position = position
var target_position:
	get:
		return _target_position
	set(value):
		set_target_position(value)
@onready var pushed = false: set = set_pushed

signal update_persistent_state

func _ready():
	add_to_group("pushable")

func interact(node):
	if motion.is_busy():
		return
	var direction = node.get_push_direction() if node.has_method("get_push_direction") else node.last_movedir
	if network.is_map_host():
		attempt_move(direction)
	else:
		network.peer_call_id(network.get_map_host(), self, "attempt_move", [direction])

func attempt_move(direction):
	if pushed or direction != Vector2.UP:
		return
	var ticket := motion.reserve(direction)
	if ticket < 0:
		return
	ray.target_position = direction * 16
	await get_tree().create_timer(0.05).timeout
	if !motion.resolve(ticket):
		return
	ray.force_raycast_update()
	if !ray.is_colliding() && direction == Vector2.UP && !pushed:
		_target_position = (position + direction * 16).snapped(Vector2(16,16)) - Vector2(8,8)
		move_to(position, _target_position)
		set_pushed(true)
		network.peer_call(self, "move_to", [position, _target_position])
		network.peer_call(self, "set_pushed", [pushed])
		network.set_state(self,{"target_position":_target_position, "pushed":pushed})

func set_target_position(value):
	release_player()
	motion.cancel()
	_target_position = value
	position = value
	
func set_pushed(value):
	pushed = value

func move_to(current_pos, target_pos):
	var animation = preload("res://effects/pushfx.tscn").instantiate()
	get_parent().add_child(animation)
	animation.position = position
	release_player()
	pushing_player = global.player
	if is_instance_valid(pushing_player):
		player_was_processing = pushing_player.is_physics_processing()
		pushing_player.set_physics_process(false)
		pushing_player.anim_switch("idle")
	tween = motion.animate(self, current_pos, target_pos, 1.0)
	tween.finished.connect(release_player)
	sfx.play("push")

func release_player():
	if is_instance_valid(pushing_player):
		pushing_player.set_physics_process(player_was_processing)
	pushing_player = null
