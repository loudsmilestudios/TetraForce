extends StaticBody2D

func _ready():
	add_to_group("subitem")
	add_to_group("nopush")

func collect(node):
	print_debug("Got a rupee!")
	queue_free()