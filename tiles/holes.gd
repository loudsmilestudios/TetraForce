extends TileMap

class_name Holes

func _ready():
	set_collision_layer_bit(0, 0)
	set_collision_mask_bit(0, 0)
	set_collision_layer_bit(1, 0)
	set_collision_mask_bit(1, 0)
	set_collision_layer_bit(7, 1)
	set_collision_mask_bit(7, 1)
