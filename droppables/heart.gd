extends Droppable

var text_name = "a heart"

func pickup(player):
	print_debug("Got a heart!")
	player.update_health(1)
	delete()
