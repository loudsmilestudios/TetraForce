extends TileMap

func _ready() -> void:
	for tile in get_used_cells():
		var tile_name: String = get_tileset().tile_get_name(get_cellv(tile))
		var node = load(str("res://enemies/", tile_name, ".tscn")).instance()
		node.global_position = map_to_world(tile) + Vector2(4,4) + get_tileset().tile_get_texture_offset(get_cellv(tile))
		get_parent().call_deferred("add_child", node)
	clear()
