extends StaticBody2D

onready var ray = $RayCast2D
onready var tween = $Tween

onready var target_position = position setget set_position

signal update_persistent_state

func _ready():
	add_to_group("pushable")

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
	if !ray.is_colliding():
		target_position = (position + direction * 16).snapped(Vector2(16,16)) - Vector2(8,8)
		emit_signal("update_persistent_state")
		move_to(position, target_position)
		network.peer_call(self, "move_to", [position, target_position])

func set_position(value):
	position = value

func move_to(current_pos, target_pos):
	tween.interpolate_property(self, "position", current_pos, target_pos, 1.0, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	tween.start()
