extends TileMap

var cut_cells = [] setget enter_cut_cells
var walkfx_texture = preload("res://effects/walkfx_grass.png")

func _ready():
	var network_object = preload("res://engine/network_object.tscn").instance()
	network_object.enter_properties = {"cut_cells":[]}
	add_child(network_object)
	add_to_group("fxtile")

func cut(hitbox):
	var hitbox_width = hitbox.get_node("CollisionShape2D").shape.extents.x * hitbox.global_scale.x
	var hitbox_height = hitbox.get_node("CollisionShape2D").shape.extents.y * hitbox.global_scale.y
	var corners = [Vector2(hitbox_width, hitbox_height), Vector2(-hitbox_width, -hitbox_height), Vector2(-hitbox_width, hitbox_height), Vector2(hitbox_width, -hitbox_height)  ]

	for offset in corners:
		var tile = world_to_map(hitbox.global_position + offset)
		process_tile(tile)
		network.peer_call(self, "process_tile", [tile])

func enter_cut_cells(value):
	cut_cells = value
	for cell in cut_cells:
		set_cellv(cell, -1)

func process_tile(tile):
	if get_cellv(tile) == -1:
		return
	cut_cells.append(tile)
	set_cellv(tile, -1)
	update_bitmask_region()
	var grass_cut = preload("res://effects/grass_cut.tscn").instance()
	network.current_map.add_child(grass_cut)
	grass_cut.global_position = map_to_world(tile) + Vector2(8,6)
	
	network.current_map.spawn_collectable("tetran", tile * 16 + Vector2(8,8), 5)
