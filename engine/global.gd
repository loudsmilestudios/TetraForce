extends Node

var player

var next_map = "dung1"
var next_entrance = "a"

signal map_change_acknowledged

func change_map(map, entrance):
	screenfx.play("fadewhite")
	yield(screenfx, "animation_finished")
	
	var old_map = network.current_map
	var root = old_map.get_parent()
	
	var new_map_path = "res://maps/" + map + ".tscn"
	var new_map = load(new_map_path).instance()
	
	for peer in network.map_peers:
		rpc_id(peer, "_receive_map_change", get_tree().get_network_unique_id())
		yield(self, "map_change_acknowledged")
		network.map_peers.erase(peer)
	
	old_map.queue_free()
	root.add_child(new_map)

remote func _receive_map_change(id):
	network.map_peers.erase(id)
	network.current_map.get_node(str(id)).remove_from_group("player")
	network.current_map.get_node(str(id)).free()
	rpc_id(id, "_acknowledge_map_change", get_tree().get_network_unique_id())

remote func _acknowledge_map_change(id):
	emit_signal("map_change_acknowledged", id)

