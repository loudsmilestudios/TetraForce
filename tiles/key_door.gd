extends StaticBody2D

onready var locked = true setget set_locked

export(String) var direction = "up"

signal update_persistent_state

func _ready():
	add_to_group("pushable")
	spritedir()
	

func interact(node):
	if network.is_map_host():
		if network.current_map.get_node("dungeon_handler").keys > 0:
			network.current_map.get_node("dungeon_handler").remove_key()
			network.peer_call(self, "unlock")
			unlock()
	else:
		network.peer_call_id(network.get_map_host(), self, "unlock")

func unlock():
	$AnimationPlayer.play("key_door_" + direction)
	yield(get_tree().create_timer(0.5), "timeout")
	$CollisionShape2D.queue_free()
	locked = false
	hide()
	
	emit_signal("update_persistent_state")

func set_locked(l):
	if !l:
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
