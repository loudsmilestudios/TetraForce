extends TileMapLayer

class_name Water

var default_cells = {}
var zone

func _ready():
	add_to_group("water")
	add_to_group("zoned")
	add_to_group("objects")
	var membership = CollisionLayers.TERRAIN | CollisionLayers.ACTOR | CollisionLayers.WATER | CollisionLayers.ZONE
	CollisionLayers.configure_tiles(self, membership, CollisionLayers.ACTOR | CollisionLayers.WATER | CollisionLayers.ZONE)
	for cell in get_used_cells():
		default_cells[cell] = [get_cell_source_id(cell), get_cell_atlas_coords(cell), get_cell_alternative_tile(cell)]

func clear_water(pos):
	var tile = local_to_map(to_local(pos))
	remove_water_tile(tile)
	network.peer_call(self, "remove_water_tile", [tile])

func remove_water_tile(tile: Vector2i):
	TerrainTiles.erase(self, tile)

func is_cell_in_zone(cellv : Vector2, action_zone):
	
	# Convert zone into Rect2, so we check for points within it.
	# Worth noting that this only handles rectangle shapes
	var collision_rect = Rect2(action_zone.collision_shape.global_position - action_zone.shape.size / 2.0,
		action_zone.shape.size)

	return collision_rect.has_point(to_global(map_to_local(cellv)))

	
func set_default_state(action_zone):
	var restored_cells := []
	for cell in default_cells.keys():
		if is_cell_in_zone(cell, action_zone):
			var data = default_cells[cell]
			set_cell(cell, data[0], data[1], data[2])
			restored_cells.append(cell)
	TerrainTiles.refresh(self, restored_cells)
