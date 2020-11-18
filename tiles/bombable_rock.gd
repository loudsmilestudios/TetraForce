extends StaticBody2D

onready var bombed = false setget set_bombed

signal update_persistent_state

func _ready():
	add_to_group("bombable")

func bombed():
	$CollisionShape2D.queue_free()
	bombed = true
	hide()
	emit_signal("update_persistent_state")

func set_bombed(b):
	if b:
		bombed()
