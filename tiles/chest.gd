extends StaticBody2D

var opened = false setget set_open

signal update_persistent_state

func _ready():
	add_to_group("interactable")

func interact(node):
	if network.is_map_host():
		open()
	else:
		network.peer_call_id(network.get_map_host(), self, "open", [])

func set_open(value):
	print(value)
	opened = value
	if opened:
		$Sprite.frame = 1

func open():
	network.peer_call(self, "set_open", [true])
	set_open(true)
	emit_signal("update_persistent_state")
