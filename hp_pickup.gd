extends Node2D

var health_value = 1

func _on_Area2D_body_entered(body):
	if body.health != body.MAX_HEALTH:
		get_tree().call_group("player", "hp_up", health_value)
		queue_free()
	
