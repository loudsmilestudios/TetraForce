extends Node2D

var picked_up = false
var health_value = 1

func _on_Area2D_body_entered(body):
	if picked_up == false and body.health != body.MAX_HEALTH:
		picked_up = true
		get_tree().call_group("player", "hp_up", health_value)
		queue_free()
	
