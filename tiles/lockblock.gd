extends StaticBody2D

var locked = true: set = set_locked

signal update_persistent_state

func _ready():
	add_to_group("pushable")

func interact(node):
	if network.is_map_host():
		if network.current_map.get_node("dungeon_handler").keys > 0:
			network.current_map.get_node("dungeon_handler").remove_key()
			unlock()
	else:
		network.peer_call_id(network.get_map_host(), self, "interact", [node])

func unlock():
	network.peer_call(self, "set_locked", [false])
	set_locked(false)
	emit_signal("update_persistent_state")
	
func set_locked(value):
	locked = value
	if !locked:
		$CollisionShape2D.queue_free()
		hide()
