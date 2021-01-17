extends StaticBody2D

onready var locked = true setget set_locked

signal update_persistent_state

func _ready():
	add_to_group("pushable")

func interact(node):
	if network.is_map_host():
		unlock()
		network.peer_call(self, "unlock")
	else:
		network.peer_call_id(network.get_map_host(), self, "unlock")

func unlock():
	if network.current_map.get_node("dungeon_handler").keys > 0:
		network.current_map.get_node("dungeon_handler").remove_key()
		emit_signal("update_persistent_state")
		$CollisionShape2D.queue_free()
		locked = false
		hide()

func set_locked(l):
	if !l:
		unlock()
