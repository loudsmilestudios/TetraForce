extends Node

var keys = 0 setget set_keys

var thorn_order = 0 setget set_thorns

signal update_persistent_state

func add_key():
	if network.is_map_host():
		set_keys(keys + 1)
		network.peer_call(self, "set_keys", [keys])
		emit_signal("update_persistent_state")
	else:
		network.peer_call_id(network.get_map_host(), self, "add_key")

func remove_key():
	if network.is_map_host():
		set_keys(keys - 1)
		network.peer_call(self, "set_keys", [keys])
		emit_signal("update_persistent_state")
	else:
		network.peer_call_id(network.get_map_host(), self, "remove_key")

func set_keys(amount):
	keys = amount
	global.player.hud.update_keys()
	
func add_thorn_order():
	if network.is_map_host():
		set_thorns(thorn_order + 1)
		network.peer_call(self, "set_thorns", [thorn_order])
		emit_signal("update_persistent_state")
	else:
		network.peer_call_id(network.get_map_host(), self, "add_thorn_order")
		
func set_thorns(amount):
	thorn_order = amount
