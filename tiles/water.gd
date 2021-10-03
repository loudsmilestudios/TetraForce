extends TileMap

class_name Water

var default_cells = {}
var zone

func _ready():
	add_to_group("water")
	add_to_group("zoned")
	add_to_group("objects")
	set_collision_layer_bit(6, 1)
	set_collision_mask_bit(6, 1)
	set_collision_layer_bit(10, 1)
	set_collision_mask_bit(10, 1)
	for cell in get_used_cells():
		default_cells[cell] = get_cellv(cell)

func clear_water(pos):
	var tile = world_to_map(pos)
	network.peer_call(self, "process_tile", [tile])
	self.set_cellv(tile, -1)
	network.peer_call(self, "set_cellv", [tile, -1])

func is_cell_in_zone(cellv : Vector2):
	var zone_shape = zone.shape
	var top_left : Vector2 = zone.global_position - zone_shape.extents
	var bottom_right : Vector2  = zone.global_position + zone_shape.extents
	var world_location : Vector2  = map_to_world(cellv)
	
	if world_location.x < top_left.x || world_location.y < top_left.y:
		return false
	if world_location.x > bottom_right.x || world_location.y > bottom_right.y:
		return false
	return true

	
func set_default_state():
	for cell in default_cells.keys():
		if is_cell_in_zone(cell):
			set_cellv(cell, default_cells[cell])
	update_bitmask_region()
