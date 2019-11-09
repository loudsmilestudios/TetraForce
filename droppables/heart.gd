extends Droppable

func pickup(player: Entity) -> void:
	print_debug("Got a heart!")
	player.update_health(1)
	delete()
