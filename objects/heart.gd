extends Subitem

func pickup(player):
	print_debug("Got a heart!")
	player.health = min(player.health+1, player.MAX_HEALTH)
	delete()
