@tool
extends Node

const DEFAULT_META = ["gid", "height", "width", "imageheight", "imagewidth", "path"]
const REPLACEMENT_SCRIPTS = {
	"res://tiles/beach.tscn": "res://tiles/shallow.gd",
	"res://tiles/dungeon1_water.tscn": "res://tiles/water.gd",
	"res://tiles/dungeon_water.tscn": "res://tiles/water.gd",
	"res://tiles/shallow_dead_grass.tscn": "res://tiles/shallow.gd",
	"res://tiles/shallow_deep.tscn": "res://tiles/water.gd",
	"res://tiles/shallow_grass.tscn": "res://tiles/shallow.gd",
	"res://tiles/shallow_shore.tscn": "res://tiles/shallow.gd",
	"res://tiles/tall_grass.tscn": "res://tiles/tall_grass.gd",
	"res://tiles/water.tscn": "res://tiles/water.gd",
	"res://tiles/wheat.tscn": "res://tiles/wheat.gd",
}

var scene: Node2D

func _post_process(imported_scene: Node2D) -> Node2D:
	scene = imported_scene
	scene.set_script(load("res://engine/game.gd"))
	scene.y_sort_enabled = true
	set_properties(scene, scene)

	var z_index := 0
	for child in scene.get_children():
		if child is TileMapLayer:
			child.z_index = z_index
			z_index += 1
			import_tilemap(child)
		elif child is Node2D:
			if child.name.to_lower() == "zones":
				import_zones(child)
			else:
				for object in child.get_children():
					spawn_object(object)
				scene.remove_child(child)
				child.free()

	return scene

func import_tilemap(tilemap: TileMapLayer) -> void:
	tilemap.z_index -= 10
	if tilemap.has_meta("script"):
		tilemap.set_script(load(str(tilemap.get_meta("script"))))
	elif tilemap.has_meta("replace"):
		var replacement_path := str(tilemap.get_meta("replace"))
		if replacement_path in REPLACEMENT_SCRIPTS:
			replace_tilemap(tilemap, replacement_path)
	CollisionLayers.configure_tiles(tilemap, CollisionLayers.WORLD | CollisionLayers.ACTOR, CollisionLayers.WORLD | CollisionLayers.ACTOR)
	if tilemap.has_meta("z_index"):
		tilemap.z_index = int(tilemap.get_meta("z_index"))
	if tilemap.has_meta("collision") and not bool(tilemap.get_meta("collision")):
		tilemap.collision_enabled = false

func replace_tilemap(tilemap: TileMapLayer, path: String) -> void:
	# Preserve the imported node's name, transform and metadata, while restoring
	# the original template's artwork, animation, terrain rules and geometry.
	var cells := tilemap.get_used_cells()
	var replacement := load(path).instantiate() as TileMapLayer
	tilemap.clear()
	tilemap.tile_set = replacement.tile_set
	tilemap.z_index = replacement.z_index
	tilemap.set_script(replacement.get_script())
	for group in replacement.get_groups():
		tilemap.add_to_group(group, true)
	for cell in cells:
		tilemap.set_cell(cell, 0, Vector2i(3, 3))
	TerrainTiles.refresh(tilemap, cells)
	replacement.free()

func import_zones(container: Node2D) -> void:
	for zone in container.get_children():
		if not zone is Area2D:
			continue
		var collision_shape: CollisionShape2D
		for child in zone.get_children():
			if child is CollisionShape2D:
				collision_shape = child
				break
		if collision_shape and collision_shape.shape is RectangleShape2D:
			collision_shape.name = "CollisionShape2D"
			collision_shape.shape.size -= Vector2(16, 16)
		zone.collision_layer = 1 << 10
		zone.collision_mask = 1 << 10
		zone.set_script(load("res://engine/zone.gd"))
		set_properties(zone, zone)

func spawn_object(object: Node2D) -> void:
	if object.has_meta("path"):
		var packed_scene := load(str(object.get_meta("path"))) as PackedScene
		if not packed_scene:
			push_error("Unable to load Tiled object scene: %s" % object.get_meta("path"))
			return
		var node := packed_scene.instantiate()
		var authored_name := str(object.get_meta("tiled_object_name", object.name))
		if !authored_name.is_empty():
			node.name = authored_name
		scene.add_child(node)
		node.owner = scene
		if node is Node2D:
			node.position = object.position + Vector2(8, -8)
			if node is PhysicsBody2D and !object.has_meta("z_index"):
				node.z_index = RenderLayers.ACTORS
		set_properties(object, node)
		object.get_parent().remove_child(object)
		object.free()
	else:
		object.reparent(scene)
		object.owner = scene

func set_properties(object: Object, node: Object) -> void:
	var properties := {}
	for property in node.get_property_list():
		properties[property.name] = true
	for meta in object.get_meta_list():
		var target_meta = "is_hidden" if meta == "hidden" else meta
		if meta not in DEFAULT_META and target_meta in properties:
			node.set(target_meta, object.get_meta(meta))
