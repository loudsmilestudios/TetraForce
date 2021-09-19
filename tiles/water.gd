extends TileMap

class_name Water

func _ready():
	add_to_group("water")
	set_collision_layer_bit(6, 1)
	set_collision_mask_bit(6, 1)

func clear_water(pos):
	var tile = world_to_map(pos)
	network.peer_call(self, "process_tile", [tile])
	self.set_cellv(tile, -1)
	network.peer_call(self, "set_cellv", [tile, -1])
