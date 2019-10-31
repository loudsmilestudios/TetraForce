extends Subitem

func _ready():
	add_to_group("subitem")
	add_to_group("nopush")
	
func on_pickup(player):
	print_debug("Got a rupee!")
	queue_free()
