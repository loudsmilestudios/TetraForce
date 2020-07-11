extends Node

var player

var next_entrance = "a"

signal map_change_acknowledged

var unacknowledged_players = []

func change_map(map, entrance):
	screenfx.play("fadewhite")
	yield(screenfx, "animation_finished")
	
	var old_map = network.current_map
	var root = old_map.get_parent()
	
	var new_map_path = "res://maps/" + map + ".tscn"
	var new_map = load(new_map_path).instance()
	
	if !get_tree().is_network_server():
		while network.player_list[get_tree().get_network_unique_id()] != str(get_tree().get_network_unique_id()):
			network.rpc_id(1, "_receive_current_map", get_tree().get_network_unique_id(), str(get_tree().get_network_unique_id()))
			yield(get_tree().create_timer(0.25), "timeout")
	else:
		network._receive_current_map(1, "1")
	
	for peer in get_tree().get_network_connected_peers():
		unacknowledged_players.append(peer)
	
	unacknowledged_players.erase(get_tree().get_network_unique_id())
	
	while unacknowledged_players.size() > 0:
		print(unacknowledged_players)
		var peers_processed = []
		for peer in get_tree().get_network_connected_peers():
			if peer == get_tree().get_network_unique_id():
				peers_processed.append(peer)
				continue
			while peer in unacknowledged_players:
				var connected_peers = []
				for p in get_tree().get_network_connected_peers():
					connected_peers.append(p)
				if !connected_peers.has(peer):
					unacknowledged_players.erase(peer)
					print(str(peer, " disconnected before map change"))
					continue
				rpc_id(peer, "_check_player_list_status", get_tree().get_network_unique_id())
				yield(get_tree().create_timer(0.25), "timeout")
			peers_processed.append(peer)
		for peer in unacknowledged_players:
			if !peers_processed.has(peer):
				print(str(peer, " disconnected before map change"))
				unacknowledged_players.erase(peer)
		yield(get_tree().create_timer(0.25), "timeout")
	
	old_map.queue_free()
	next_entrance = entrance
	root.add_child(new_map)

remote func _check_player_list_status(id):
	if str(network.player_list[id]) != str(network.current_map):
		rpc_id(id, "_send_player_list_status_success", get_tree().get_network_unique_id())
	else:
		rpc_id(id, "_send_player_list_status_fail", get_tree().get_network_unique_id())

remote func _send_player_list_status_success(id):
	if unacknowledged_players.has(id):
		unacknowledged_players.erase(id)
		print(str(id, " check succeeded"))

remote func _send_player_list_status_fail(id):
	print(str(id, " check failed"))
