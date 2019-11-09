class_name entity_helper

static func rand_direction() -> Vector2:
	var new_direction: int = randi() % 4 + 1
	match new_direction:
		1:
			return Vector2.LEFT
		2:
			return Vector2.RIGHT
		3:
			return Vector2.UP
		4:
			return Vector2.DOWN
	return Vector2(0, 0)
