extends StaticBody2D

class_name Subitem

func _ready():
	add_to_group("subitem")
	add_to_group("nopush")
	pass

func on_pickup(player):
	if get_tree().get_network_unique_id() == int(player.name):
		pickup(player)

func pickup(player):
	pass

func delete():
	for peer in network.map_peers:
		rpc_id(peer, "_remote_delete")
	queue_free()
	pass

remote func _remote_delete():
	queue_free()
	pass
