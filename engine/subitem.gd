extends StaticBody2D

class_name Subitem

func _ready():
	#$"Hitbox".connect("body_entered", self, "body_entered")
	add_to_group("subitem")
	add_to_group("nopush")
	pass

func body_entered(body):
	if body.get_groups().has("player"):
		on_pickup(body)
	pass

func on_pickup(player):
	pass

sync func delete():
	queue_free()
	pass
