extends TileMap

var cut_cells = [] setget enter_cut_cells

signal update_persistent_state

func _ready():
	var network_object = preload("res://engine/network_object.tscn").instance()
	network_object.persistent = true
	network_object.enter_properties = {"cut_cells":[]}
	add_child(network_object)

func cut(hitbox):
	var tile = world_to_map(hitbox.global_position)
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
	emit_signal("update_persistent_state")
	set_cellv(tile, -1)
	update_bitmask_region()
	var grass_cut = preload("res://effects/grass_cut.tscn").instance()
	network.current_map.add_child(grass_cut)
	grass_cut.global_position = map_to_world(tile) + Vector2(8,6)
