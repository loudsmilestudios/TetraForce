extends Node

var scene

func post_import(imported_scene):
	scene = imported_scene
	
	# add game.gd script
	scene.set_script(preload("res://game.gd"))
	
	for child in scene.get_children():
		if child is TileMap:
			import_tilemap(child)
		elif child is Node2D:
			for object in child.get_children():
				spawn_object(object)
			child.free()
	
	return scene

func import_tilemap(tilemap):
	tilemap.position.y += 16

func spawn_object(object):
	if object.has_meta("path"):
		var path = object.get_meta("path")
		
		var node = load(path).instance()
		scene.add_child(node)
		node.set_owner(scene)
		node.position = object.position
	
	else:
		object.get_parent().remove_child(object)
		scene.add_child(object)
		object.set_owner(scene)
