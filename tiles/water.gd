extends TileMap

class_name Water

var default_cells = []
var zone

func _ready():
	add_to_group("water")
	add_to_group("zoned")
	add_to_group("objects")
	set_collision_layer_bit(6, 1)
	set_collision_mask_bit(6, 1)
	set_collision_layer_bit(10, 1)
	set_collision_mask_bit(10, 1)

func clear_water(pos):
	var tile = world_to_map(pos)
	network.peer_call(self, "process_tile", [tile])
	self.set_cellv(tile, -1)
	network.peer_call(self, "set_cellv", [tile, -1])
	default_cells.append(tile)
	print(default_cells)
	
func set_default_state():
	for cell in default_cells:
		if zone.world_to_map(cell):
			set_cellv(cell, default_cells[cell])
	update_bitmask_region()
