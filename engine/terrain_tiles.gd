extends RefCounted
class_name TerrainTiles

# Repaint the original 3x3-minimal patterns using the migrated terrain data.
# Godot 4's terrain solver treats diagonal contacts differently: an occupied
# diagonal must not fill a corner unless BOTH adjoining sides are occupied.
const PEERING_BITS = {
	1: TileSet.CELL_NEIGHBOR_TOP_LEFT_CORNER,
	2: TileSet.CELL_NEIGHBOR_TOP_SIDE,
	4: TileSet.CELL_NEIGHBOR_TOP_RIGHT_CORNER,
	8: TileSet.CELL_NEIGHBOR_LEFT_SIDE,
	32: TileSet.CELL_NEIGHBOR_RIGHT_SIDE,
	64: TileSet.CELL_NEIGHBOR_BOTTOM_LEFT_CORNER,
	128: TileSet.CELL_NEIGHBOR_BOTTOM_SIDE,
	256: TileSet.CELL_NEIGHBOR_BOTTOM_RIGHT_CORNER,
}

static func erase(layer: TileMapLayer, cell: Vector2i) -> void:
	layer.erase_cell(cell)
	refresh(layer, [cell])

static func refresh(layer: TileMapLayer, changed_cells: Array) -> void:
	if !layer.tile_set or !layer.tile_set.get_meta("legacy_autotile", false):
		return
	var source := layer.tile_set.get_source(0) as TileSetAtlasSource
	var patterns := {}
	for index in source.get_tiles_count():
		var coords := source.get_tile_id(index)
		var data := source.get_tile_data(coords, 0)
		var mask := 16
		for bit in PEERING_BITS:
			if data.get_terrain_peering_bit(PEERING_BITS[bit]) == 0:
				mask |= bit
		patterns[mask] = coords
	var neighborhoods := {}
	for cell in changed_cells:
		for x in range(-1, 2):
			for y in range(-1, 2):
				neighborhoods[Vector2i(cell) + Vector2i(x, y)] = true
	for cell in neighborhoods:
		if layer.get_cell_source_id(cell) == -1:
			continue
		var mask := 16
		for offset in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if layer.get_cell_source_id(cell + offset) != -1:
				mask |= 1 << ((offset.y + 1) * 3 + offset.x + 1)
		for offset in [Vector2i(-1, -1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(1, 1)]:
			var diagonal := layer.get_cell_source_id(cell + offset) != -1
			var horizontal := layer.get_cell_source_id(cell + Vector2i(offset.x, 0)) != -1
			var vertical := layer.get_cell_source_id(cell + Vector2i(0, offset.y)) != -1
			if diagonal and horizontal and vertical:
				mask |= 1 << ((offset.y + 1) * 3 + offset.x + 1)
		layer.set_cell(cell, 0, patterns[mask])
