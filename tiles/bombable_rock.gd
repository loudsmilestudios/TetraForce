extends StaticBody2D

onready var bombed = false setget set_bombed

signal update_persistent_state

func _ready():
	add_to_group("bombable")

func bombed(show_animation=true):
	$CollisionShape2D.queue_free()
	bombed = true
	hide()
	if show_animation:
		var animation = preload("res://effects/bombable_rock_explosion.tscn").instance()
		get_parent().add_child(animation)
		animation.position = position
	emit_signal("update_persistent_state")

func set_bombed(b):
	if b:
		bombed(false)
