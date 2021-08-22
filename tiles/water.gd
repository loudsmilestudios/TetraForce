extends TileMap

class_name Water

func _ready():
	add_to_group("water")
	set_collision_layer_bit(6, 1)
	set_collision_mask_bit(6, 1)
