extends Droppable
	
func pickup(player):
	print_debug("Got a rupee!")
	delete()
