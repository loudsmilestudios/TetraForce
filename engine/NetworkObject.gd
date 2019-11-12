extends Node

class_name NetworkObject

var is_server_managed = false

var flag_list = {}

func _received_flag_update(flag_name, value):
	pass

func net_get_flag(flag_name):
	return flag_list.get(flag_name)
	
func net_set_flag(flag_name, value):
	var was = flag_list.get(flag_name, value)
	flag_list[flag_name] = value

	#Data is new and non-initial
	if was != value:
		if is_server_managed:
			if get_tree().is_network_server():
				network.update_server_object_flag(get_name(), flag_name, value)
			else:
				rpc_id(global.player.get_network_master(), "update_server_object_flag", get_name(), flag_name, value)
		else:
			for peer in network.map_peers:
				rpc_id(peer, "update_object_flag", get_name(), flag_name, value)
