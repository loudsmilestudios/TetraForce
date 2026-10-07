extends StaticBody2D

@export var starts_locked: bool = false
@export var location: String = "room"
@export var direction: String = "up"
#export var texture = "dungeon1" no textures implemented yet

@onready var locked = false: set = set_locked

signal on_button_pressed
signal no_weight

func _ready():
	spritedir()
	get_parent().get_node(location).connect("on_button_pressed", Callable(self, "unlock"))
	get_parent().get_node(location).connect("no_weight", Callable(self, "lock"))
	set_locked(starts_locked)
		
func lock():
	if locked:
		return
	if !locked && $AnimationPlayer.current_animation != "lock_" + direction:
		$AnimationPlayer.play("lock_" + direction)
		await $AnimationPlayer.animation_finished
		set_locked(true)

func unlock():
	if !locked:
		return
	if locked && $AnimationPlayer.current_animation != "unlock_" + direction:
		$AnimationPlayer.play("unlock_" + direction)
		await $AnimationPlayer.animation_finished
		set_locked(false)

func set_locked(value):
	locked = value
	if !locked:
		$AnimationPlayer.play("unlocked_" + direction)
	else:
		$AnimationPlayer.play("locked_" + direction)
		
func spritedir():
	if direction == "up":
		$Sprite2D.frame = 8
	elif direction == "right":
		$Sprite2D.frame = 4
	elif direction == "down":
		$Sprite2D.frame = 0
	elif direction == "left":
		$Sprite2D.frame = 12
