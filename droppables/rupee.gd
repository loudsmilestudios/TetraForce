extends Droppable
	
func pickup(player) -> void:
	print_debug("Got a rupee!")
	# TODO: update player rupee count
	delete()
