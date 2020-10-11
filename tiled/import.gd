tool
extends Node

var scene

const default_meta = ["gid", "height", "width", "imageheight", "imagewidth", "path"]

func post_import(imported_scene):
	scene = imported_scene
	
	# add game.gd script
	scene.set_script(preload("res://engine/game.gd"))
	
	var z = 0
	var children = scene.get_children()
	for child in children:
		if child is TileMap:
			child.z_index = z
			z += 1
			import_tilemap(child)
		elif child is Node2D:
			for object in child.get_children():
				spawn_object(object)
			child.free()
	
	return scene

func import_tilemap(tilemap):
	tilemap.position.y += 16
	tilemap.z_index -= 10
	var z = tilemap.z_index
	
	if tilemap.name == "tall_grass":
		var used_cells = tilemap.get_used_cells()
		tilemap.free()
		var new_grass = preload("res://tiles/tall_grass.tscn").instance()
		scene.add_child(new_grass)
		new_grass.set_owner(scene)
		for cell in used_cells:
			new_grass.set_cellv(cell, 0)
			new_grass.update_bitmask_region()
	elif tilemap.name == "bush":
		tilemap.set_script(preload("res://tiles/tall_grass.gd"))
	elif tilemap.name == "water":
		var used_cells = tilemap.get_used_cells()
		tilemap.free()
		var new_water = preload("res://tiles/water.tscn").instance()
		scene.add_child(new_water)
		new_water.set_owner(scene)
		new_water.z_index = z
		for cell in used_cells:
			new_water.set_cellv(cell, 0)
			new_water.update_bitmask_region()
	
	else:
		tilemap.set_collision_layer_bit(1,1)
		tilemap.set_collision_mask_bit(1,1)

func spawn_object(object):
	if object.has_meta("path"):
		var path = object.get_meta("path")
		
		var node = load(path).instance()
		scene.add_child(node)
		node.set_owner(scene)
		node.position = object.position + Vector2(8,-8)
		
		for meta in object.get_meta_list():
			if meta in default_meta:
				continue
			node.set(meta, object.get_meta(meta))
	
	else:
		object.get_parent().remove_child(object)
		scene.add_child(object)
		object.set_owner(scene)
		
