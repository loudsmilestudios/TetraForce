extends Area2D

var player

func _ready() -> void:
	add_to_group("entity_detect")

func _process(delta) -> void:
	if !is_instance_valid(player):
		remove_from_group("entity_detect")
		queue_free()
	
	position = get_grid_pos(player.position) * Vector2(256, 144)

func get_grid_pos(pos) -> Vector2:
	var x: float = floor(pos.x / 256)
	var y: float = floor(pos.y / 144)
	
	return Vector2(x, y)
