extends StaticBody2D

export(bool) var enemy_trigger = false
export(bool) var starts_locked = false
export(String) var location = "room"
export(String) var direction = "up"
export var texture = "dungeon1"

onready var locked = true setget set_locked

func _ready():
	spritedir()
	lock()
	get_parent().get_node(location).connect("finished", self, "set_locked", [false])
	get_parent().get_node(location).connect("started", self, "set_locked", [true])
	get_parent().get_node(location).connect("reset", self, "set_reset")
	if !starts_locked:
		locked = false
		unlock()
		
func lock():
	$AnimationPlayer.play("enemy_lock_" + direction)
	network.peer_call($AnimationPlayer, "play", ["enemy_lock_" + direction])
	set_locked(true)

func unlock():
	$AnimationPlayer.play("enemy_unlock_" + direction)
	network.peer_call($AnimationPlayer, "play", ["enemy_unlock_" + direction])
	
func set_reset():
	lock()
	if !starts_locked:
		locked = false
		if network.is_map_host():
			network.peer_call(self, "unlock")
		unlock()

func set_locked(value):
	if locked == value:
		return
	if network.is_map_host():
		network.peer_call(self, "set_locked", [value])
	locked = value
	if !locked:
		unlock()
	else:
		lock()
		
func spritedir():
	if direction == "up":
		$Sprite.frame = 20
	elif direction == "right":
		$Sprite.frame = 10
	elif direction == "down":
		$Sprite.frame = 0
	elif direction == "left":
		$Sprite.frame = 30
