extends Node

class_name NetworkObject

var is_server_managed = false

var flag_list = {}

func _received_flag_update(flag_name, value):
	pass

func set_flag(flag_name, value):
	var was = flag_list.get(flag_name, value)
	flag_list[flag_name] = value

	#Data is new and non-initial
	if was != value:
		if is_server_managed:
			rpc_id(1, "update_server_object_flag", get_name(), flag_name, value)
		else:
			for peer in network.map_peers:
				rpc_id(peer, "update_object_flag", get_name(), flag_name, value)
