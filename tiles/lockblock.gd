extends StaticBody2D

onready var locked = true setget set_locked

signal update_persistent_state

func _ready():
	add_to_group("pushable")

func interact(node):
	if network.is_map_host():
		if network.current_map.get_node("dungeon_handler").keys > 0:
			network.current_map.get_node("dungeon_handler").remove_key()
			network.peer_call(self, "unlock")
			unlock()
	else:
		network.peer_call_id(network.get_map_host(), self, "unlock")

func unlock():
	$CollisionShape2D.queue_free()
	locked = false
	hide()
	
	emit_signal("update_persistent_state")

func set_locked(l):
	if !l:
		unlock()
