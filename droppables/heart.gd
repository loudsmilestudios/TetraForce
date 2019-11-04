extends Droppable

func pickup(player):
	print_debug("Got a heart!")
	player.update_health(1)
	delete()
