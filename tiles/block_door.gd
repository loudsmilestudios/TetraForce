extends StaticBody2D

export(bool) var starts_locked = false
export(String) var location = "room"
export(String) var direction = "up"
#export var texture = "dungeon1" no textures implemented yet

onready var locked = false setget set_locked

signal on_button_pressed
signal no_weight

func _ready():
	spritedir()
	get_parent().get_node(location).connect("on_button_pressed", self, "unlock")
	get_parent().get_node(location).connect("no_weight", self, "lock")
	set_locked(starts_locked)
		
func lock():
	if locked:
		return
	if !locked && $AnimationPlayer.current_animation != "lock_" + direction:
		$AnimationPlayer.play("lock_" + direction)
		yield($AnimationPlayer, "animation_finished")
		set_locked(true)

func unlock():
	if !locked:
		return
	if locked && $AnimationPlayer.current_animation != "unlock_" + direction:
		$AnimationPlayer.play("unlock_" + direction)
		yield($AnimationPlayer, "animation_finished")
		set_locked(false)

func set_locked(value):
	locked = value
	if !locked:
		$AnimationPlayer.play("unlocked_" + direction)
	else:
		$AnimationPlayer.play("locked_" + direction)
		
func spritedir():
	if direction == "up":
		$Sprite.frame = 8
	elif direction == "right":
		$Sprite.frame = 4
	elif direction == "down":
		$Sprite.frame = 0
	elif direction == "left":
		$Sprite.frame = 12
