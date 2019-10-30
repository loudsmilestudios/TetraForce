extends Area2D
class_name Destructible

func _ready():
	connect("area_entered", self, "_on_Body_entered")

func _on_Body_entered(body):
	queue_free()