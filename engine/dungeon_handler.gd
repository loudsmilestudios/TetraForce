extends Node

var keys = 0

signal update_persistent_state

func add_key():
	if network.is_map_host():
		set_keys(keys + 1)
		network.peer_call(self, "set_keys", [keys])
		emit_signal("update_persistent_state")
	else:
		network.peer_call(self, "add_key")

func remove_key():
	if network.is_map_host():
		set_keys(keys - 1)
		network.peer_call(self, "set_keys", [keys])
		emit_signal("update_persistent_state")
	else:
		network.peer_call(self, "remove_key")

func set_keys(amount):
	keys = amount
	global.player.hud.update_keys()
