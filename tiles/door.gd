extends StaticBody2D

export var is_locked = true
export var has_key = false # key_id ?
export var key_id = 0
export(String, "SMALL_KEY", "BOSS_KEY", "EVENT_KEY") var key_type


func unlock(key):
	if (has_key || key_type == "EVENT_KEY") && key_id != key:
		return
	# Do fancy animation or something, then remove door
	queue_free()