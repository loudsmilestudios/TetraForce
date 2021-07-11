extends StaticBody2D

export(bool) var enemy_trigger = false
export(bool) var starts_locked = false
export(String) var location = "room"
export(String) var direction = "up"
export var texture = "dungeon1"

onready var locked = false setget set_locked
onready var inactive = false setget set_inactive

func _ready():
	spritedir()
	get_parent().get_node(location).connect("finished", self, "set_locked", [false])
	get_parent().get_node(location).connect("started", self, "set_locked", [true])
	get_parent().get_node(location).connect("check_for_active", self, "check_lock_state")
	get_parent().get_node(location).connect("check_for_inactive", self, "check_lock_state")
	get_parent().get_node(location).connect("reset", self, "set_reset")
	if starts_locked && inactive == false:
		$AnimationPlayer.play("enemy_locked_" + direction)
		network.peer_call($AnimationPlayer, "play", ["enemy_locked_" + direction])
		locked = true
		
func lock():
	if !starts_locked:
		$AnimationPlayer.play("enemy_lock_" + direction)
		network.peer_call($AnimationPlayer, "play", ["enemy_lock_" + direction])
		set_locked(true)

func unlock():
	if starts_locked && inactive:
		$AnimationPlayer.play("enemy_unlock_" + direction)
		network.peer_call($AnimationPlayer, "play", ["enemy_unlocked_" + direction])
	else:
		$AnimationPlayer.play("enemy_unlock_" + direction)
		network.peer_call($AnimationPlayer, "play", ["enemy_unlock_" + direction])
		set_locked(false)
		set_inactive(true)

func check_lock_state():
	if locked == true:
		$AnimationPlayer.play("enemy_locked_" + direction)
		network.peer_call($AnimationPlayer, "play", ["enemy_locked_" + direction])
	if locked == false:
		$AnimationPlayer.play("enemy_unlocked_" + direction)
		network.peer_call($AnimationPlayer, "play", ["enemy_unlocked_" + direction])
	
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
		
func set_inactive(value):
	if inactive == value:
		return
	if network.is_map_host():
		network.peer_call(self, "set_inactive", [value])
	inactive = value
		
func spritedir():
	if direction == "up":
		$Sprite.frame = 20
	elif direction == "right":
		$Sprite.frame = 10
	elif direction == "down":
		$Sprite.frame = 0
	elif direction == "left":
		$Sprite.frame = 30
