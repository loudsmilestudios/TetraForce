extends StaticBody2D

@export var enemy_trigger: bool = false
@export var starts_locked: bool = false
@export var location: String = "room"
@export var direction: String = "up"
@export var texture = "dungeon1"

@onready var locked = false: set = set_locked
@onready var inactive = false: set = set_inactive

func _ready():
	spritedir()
	get_parent().get_node(location).connect("finished", Callable(self, "set_locked").bind(false))
	get_parent().get_node(location).connect("started", Callable(self, "set_locked").bind(true))
	get_parent().get_node(location).connect("check_for_active", Callable(self, "check_lock_state"))
	get_parent().get_node(location).connect("check_for_inactive", Callable(self, "check_lock_state"))
	get_parent().get_node(location).connect("reset", Callable(self, "set_reset"))
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
		$Sprite2D.frame = 20
	elif direction == "right":
		$Sprite2D.frame = 10
	elif direction == "down":
		$Sprite2D.frame = 0
	elif direction == "left":
		$Sprite2D.frame = 30
