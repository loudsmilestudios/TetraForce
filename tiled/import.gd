tool
extends Node

var scene

const default_meta = ["gid", "height", "width", "imageheight", "imagewidth", "path"]

func post_import(imported_scene):
	scene = imported_scene
	
	# add game.gd script
	scene.set_script(preload("res://engine/game.gd"))
	set_properties(scene, scene)
	
	var z = 0
	var children = scene.get_children()
	for child in children:
		if child is TileMap:
			child.z_index = z
			z += 1
			import_tilemap(child)
		elif child is Node2D:
			if child.name == "zones":
				for zone in child.get_children():
					zone.get_node("CollisionShape2D").shape.extents -= Vector2(8,8)
					zone.set_collision_layer_bit(0, 0)
					zone.set_collision_mask_bit(0, 0)
					zone.set_collision_layer_bit(10, 1)
					zone.set_collision_mask_bit(10, 1)
					zone.set_script(preload("res://engine/zone.gd"))
					set_properties(zone, zone)
				continue
			for object in child.get_children():
				spawn_object(object)
			child.free()
	
	return scene

func import_tilemap(tilemap):
	tilemap.z_index -= 10
	tilemap.set_collision_layer_bit(1,1)
	tilemap.set_collision_mask_bit(1,1)
	tilemap.position.y += 16
	if tilemap.has_meta("script"):
		tilemap.set_script(load(tilemap.get_meta("script")))
	if tilemap.has_meta("replace"):
		replace_tilemap(tilemap, tilemap.get_meta("replace"))
	if tilemap.has_meta("z_index"):
		tilemap.z_index = tilemap.get_meta("z_index")
	if tilemap.has_meta("collision"):
		tilemap.set_collision_layer_bit(0, 0)
		tilemap.set_collision_layer_bit(1, 0)
		tilemap.set_collision_mask_bit(0, 0)
		tilemap.set_collision_mask_bit(1, 0)

func spawn_object(object):
	if object.has_meta("path"):
		var path = object.get_meta("path")

		var node = load(path).instance()
		scene.add_child(node)
		node.set_owner(scene)
		node.position = object.position + Vector2(8,-8)
		#node.scale.x = object.get_meta("width") / 16
		#node.scale.y = object.get_meta("height") / 16
		#node.position += Vector2((node.scale.x-1)*8, -(node.scale.y-1)*8)
		
		set_properties(object, node)
	
	else:
		object.get_parent().remove_child(object)
		scene.add_child(object)
		object.set_owner(scene)

func replace_tilemap(tilemap, replace):
	var used_cells = tilemap.get_used_cells()
	var replacement = load(replace).instance()
	tilemap.free()
	scene.add_child(replacement)
	replacement.set_owner(scene)
	for cell in used_cells:
		replacement.set_cellv(cell, 0)
		replacement.update_bitmask_region()
	#set_properties(tilemap, replacement)

func set_properties(object, node):
	for meta in object.get_meta_list():
		if meta in default_meta:
			continue
		node.set(meta, object.get_meta(meta))
