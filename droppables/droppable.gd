extends Area2D

class_name Droppable

func _ready():
	add_to_group("subitem")
	add_to_group("nopush")
	connect("body_entered", self, "body_entered")
	connect("area_entered", self, "area_entered")
	pass

func body_entered(body):
	if get_tree().get_network_unique_id() == int(body.name):
		pickup(body)

func area_entered(area):
	if area.get_parent().name == "Sword":
		var player = area.get_parent().get_parent()
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
