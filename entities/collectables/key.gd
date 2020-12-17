extends Collectable

func _on_collect(body):
	if network.current_map.has_node("dungeon_handler"):
		network.current_map.get_node("dungeon_handler").add_key()
	else:
		printerr("no dungeon handler found")
