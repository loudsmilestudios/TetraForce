extends TileMapLayer

var cut_cells = []: set = enter_cut_cells

var walkfx_texture = preload("res://effects/walkfx_wheat.png")

func _ready():
	CollisionLayers.configure_tiles(self, CollisionLayers.WALKFX, CollisionLayers.WALKFX)
	var network_object = preload("res://engine/network_object.tscn").instantiate()
	network_object.enter_properties = {"cut_cells":[]}
	add_child(network_object)
	add_to_group("fxtile")

func cut(hitbox):
	var tile = local_to_map(to_local(hitbox.global_position))
	process_tile(tile)
	network.peer_call(self, "process_tile", [tile])

func enter_cut_cells(value):
	cut_cells = value
	for cell in cut_cells:
		erase_cell(cell)
	TerrainTiles.refresh(self, cut_cells)

func process_tile(tile):
	if get_cell_source_id(tile) == -1:
		return
	cut_cells.append(tile)
	TerrainTiles.erase(self, tile)
	var wheat_cut = preload("res://effects/wheat_cut.tscn").instantiate()
	network.current_map.add_child(wheat_cut)
	wheat_cut.global_position = to_global(map_to_local(tile) + Vector2(0,-2))
	
	var collectable_position = network.current_map.to_local(to_global(map_to_local(tile)))
	network.current_map.spawn_collectable("tetran", collectable_position, 5)
