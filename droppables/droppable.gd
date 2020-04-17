extends Area2D

class_name Droppable

func _ready() -> void:
	add_to_group("subitem")
	add_to_group("nopush")
	connect("body_entered", self, "body_entered")
	connect("area_entered", self, "area_entered")

func body_entered(body) -> void:
	if get_tree().get_network_unique_id() == int(body.name):
		pickup(body)

func area_entered(area) -> void:
	if area.get_parent().name == "Sword":
		var player: Node = area.get_parent().get_parent()
		if get_tree().get_network_unique_id() == int(player.name):
			pickup(player)

func pickup(player: Entity):
	pass

func delete() -> void:
	for peer in network.map_peers:
		rpc_id(peer, "_remote_delete")
	queue_free()

remote func _remote_delete() -> void:
	queue_free()
