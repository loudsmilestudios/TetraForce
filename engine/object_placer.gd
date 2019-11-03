extends TileMap

func _ready():
	for tile in get_used_cells():
		var tile_name = get_tileset().tile_get_name(get_cellv(tile))
		var tile_path = ""
		if tile_name.begins_with("tile_"):
			tile_name.erase(0, 5)
			tile_path = "res://tiles/"+tile_name+".tscn"
		elif tile_name.begins_with("obj_"):
			tile_name.erase(0, 4)
			tile_path = "res://objects/"+tile_name+".tscn"
		else:
			tile_path = "res://enemies/"+tile_name+".tscn"
		
		var node = load(tile_path).instance()
		node.name = tile_name + str(tile)
		node.global_position = map_to_world(tile) + Vector2(8,8) + get_tileset().tile_get_texture_offset(get_cellv(tile))
		get_parent().call_deferred("add_child", node)
	clear()
