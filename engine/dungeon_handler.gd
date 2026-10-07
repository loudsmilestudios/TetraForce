extends Node

var keys = 0: set = set_keys

var thorn_order = 0: set = set_thorns

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
	# Saved JSON state supplies floats, but dungeon counters must stay integers.
	keys = int(amount)
	# Persistent state may arrive before the local player/HUD is initialized.
	if is_instance_valid(global.player) and global.player is Player and is_instance_valid(global.player.hud):
		global.player.hud.update_keys()
	
func add_thorn_order():
	if network.is_map_host():
		set_thorns(thorn_order + 1)
		network.peer_call(self, "set_thorns", [thorn_order])
		emit_signal("update_persistent_state")
	else:
		network.peer_call_id(network.get_map_host(), self, "add_thorn_order")
		
func set_thorns(amount):
	thorn_order = int(amount)
