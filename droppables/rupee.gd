extends Droppable
	
func pickup(player):
	sfx.play(preload("res://droppables/get_rupee.wav"), .5)
	print_debug("Got a rupee!")
	delete()
