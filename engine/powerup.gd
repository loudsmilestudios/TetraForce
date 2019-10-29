extends Node2D

class_name Powerup

func _ready():
	$"Hitbox".connect("body_entered", self, "body_entered")
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