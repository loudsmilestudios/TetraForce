extends Subitem

func _ready():
	pass
	
func on_pickup(player):
	print_debug("Got a heart!")
	player.health = min(player.health+1, player.MAX_HEALTH)
	queue_free()