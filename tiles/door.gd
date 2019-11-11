extends StaticBody2D

export var is_locked: bool = true
export var has_key: bool = false # Should be false if we have an EVENT_KEY, since events handle unlocking
export var key_id = 0 # Unique key id (NYI, not to be confused with event_key_id)
export(String, "EVENT_KEY", "SMALL_KEY", "BOSS_KEY") var key_type: String


func _ready() -> void:
	set_process(false)
	set_physics_process(false)


func attempt_unlock(key) -> void:
	# Event keys are linked with their own key_id, so we can ignore it
	if has_key && key_id != key:
		return
	unlock()


func unlock() -> void:
	is_locked = false
	# Do fancy animation or something, then make door inactive
	visible = false
	set_collision_layer_bit(0, 0)
	set_collision_layer_bit(1, 0)


# We don't use this yet, but can come in handy for events that lock the door
func lock() -> void:
	is_locked = true
	visible = true
	set_collision_layer_bit(0, 1)
	set_collision_layer_bit(1, 1)
	# Do fancy animation
