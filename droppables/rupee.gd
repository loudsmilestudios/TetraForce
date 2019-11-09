extends Droppable

var text_name = "$1"

func pickup(player):
	print_debug("Got a rupee!")
	delete()
