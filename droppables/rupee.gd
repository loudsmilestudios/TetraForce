extends Droppable
	
func pickup(player):
	sfx.play(preload("res://droppables/get_rupee.wav"))
	print_debug("Got a rupee!")
	delete()
