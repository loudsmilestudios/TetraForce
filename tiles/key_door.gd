extends StaticBody2D

@onready var locked = true: set = set_locked

@export var direction: String = "up"
@export var texture = "dungeon1"

signal update_persistent_state

func _ready():
	add_to_group("pushable")
	spritedir()
	match texture:
		"dungeon1":
			$Sprite2D.texture = preload("res://tiles/dungeon1_key_door.png")
		"cave":
			$Sprite2D.texture = preload("res://tiles/cave_key_door.png")

	

func interact(node):
	if network.is_map_host():
		if network.current_map.get_node("dungeon_handler").keys > 0:
			network.current_map.get_node("dungeon_handler").remove_key()
			unlock()
	else:
		network.peer_call_id(network.get_map_host(), self, "interact", [node])

func unlock():
	$AnimationPlayer.play("key_door_" + direction)
	await get_tree().create_timer(0.5).timeout
	network.peer_call(self, "set_locked", [false])
	set_locked(false)
	emit_signal("update_persistent_state")

func set_locked(value):
	locked = value
	if !locked:
		$CollisionShape2D.queue_free()
		hide()
		
func spritedir():
	if direction == "up":
		$Sprite2D.frame = 3
	elif direction == "right":
		$Sprite2D.frame = 7
	elif direction == "down":
		$Sprite2D.frame = 11
	elif direction == "left":
		$Sprite2D.frame = 15
