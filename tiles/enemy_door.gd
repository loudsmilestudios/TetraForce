extends StaticBody2D

export(bool) var enemy_trigger = false
export(bool) var starts_locked = false
export(String) var location = "room"
export(String) var direction = "up"
export var texture = "dungeon1"

onready var locked = true setget set_locked

signal update_persistent_state

func _ready():
	spritedir()
	lock()
	get_parent().get_node(location).connect("finished", self, "unlock")
	get_parent().get_node(location).connect("started", self, "lock")
	if enemy_trigger == false && starts_locked == false:
		unlock()
		
func lock():
	#$AnimationPlayer.play("key_lock_" + direction)
	$CollisionShape2D.disabled = false
	visible = true

func unlock():
	#$AnimationPlayer.play("key_door_" + direction)
	#yield(get_tree().create_timer(0.5), "timeout")
	#network.peer_call(self, "set_locked", [false])
	#set_locked(false)
	#emit_signal("update_persistent_state")
	$CollisionShape2D.disabled = true
	visible = false

func set_locked(value):
	locked = value
	if !locked:
		#$CollisionShape2D.queue_free()
		#hide()
		unlock()
		
func spritedir():
	if direction == "up":
		$Sprite.frame = 3
	elif direction == "right":
		$Sprite.frame = 7
	elif direction == "down":
		$Sprite.frame = 11
	elif direction == "left":
		$Sprite.frame = 15
