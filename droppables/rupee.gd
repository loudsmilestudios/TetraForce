extends Droppable

func pickup(player) -> void:
	sfx.play(preload("res://droppables/get_rupee.wav"), .5)
	print_debug("Got a rupee!")
	# TODO: update player rupee count
	delete()
