extends StaticBody2D

var _is_bombed = false
var is_bombed:
	get:
		return _is_bombed
	set(value):
		set_bombed(value)

@export var direction: String = "up"

signal update_persistent_state

func _ready():
	add_to_group("bombable")
	spritedir()

func bombed(show_animation=true):
	if _is_bombed:
		return
	_is_bombed = true
	$CollisionShape2D.queue_free()
	hide()
	if show_animation:
		var animation = preload("res://effects/bombable_rock_explosion2.tscn").instantiate()
		get_parent().add_child(animation)
		animation.position = position
		animation.rotation = rotation
	emit_signal("update_persistent_state")

func set_bombed(b):
	if b:
		bombed(false)
	else:
		_is_bombed = false

func spritedir():
	if direction == "up":
		self.rotation_degrees = 0
	elif direction == "right":
		self.rotation_degrees = 90
	elif direction == "down":
		self.rotation_degrees = 180
	elif direction == "left":
		self.rotation_degrees = 270
