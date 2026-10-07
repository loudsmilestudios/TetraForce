# MIT License
#
# Copyright (c) 2023-2026 Roland Helmerichs
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

@tool
extends RefCounted

const FLIPPED_HORIZONTALLY_FLAG = 0x80000000
const FLIPPED_VERTICALLY_FLAG = 0x40000000
const FLIPPED_DIAGONALLY_FLAG = 0x20000000

const BACKGROUND_COLOR_RECT_NAME = "Background Color"
const WARNING_COLOR = "Yellow"
const CUSTOM_DATA_INTERNAL = "__internal__"
const CLASS_INTERNAL = "class"
const GODOT_NODE_TYPE_PROPERTY = "godot_node_type"
const GODOT_GROUP_PROPERTY = "godot_group"
const GODOT_SCRIPT_PROPERTY = "godot_script"
const DEFAULT_ALIGNMENT = "unspecified"

var _map_orientation: String
var _map_width: int = 0
var _map_height: int = 0
var _map_tile_width: int = 0
var _map_tile_height: int = 0
var _infinite = false
var _parallax_origin_x: int = 0
var _parallax_origin_y: int = 0
var _background_color = ""

var _tilemap_layer = null
var _tileset = null
var _current_tileset_orientation: String
var _current_object_alignment: String
var _base_node = null
var _parallax_background = null
var _background = null
var _parallax_layer_existing = false

var _base_path = ""
var _base_name = ""
var _encoding = ""
var _compression = ""
var _first_gids = []
var _atlas_sources = null
var _use_default_filter = false
var _map_wangset_to_terrain = false
var _add_class_as_metadata = false
var _add_id_as_metadata = false
var _dont_use_alternative_tiles = false
var _custom_data_prefix: String = ""
var _tileset_save_path: String = ""
var _object_groups
var _ct: CustomTypes = null
var _base_dictionary: Dictionary

var _iso_rot: float = 0.0
var _iso_skew: float = 0.0
var _iso_scale: Vector2

var _godot_version: int

enum _godot_type {
	EMPTY,
	BODY,
	CBODY,
	RBODY,
	ABODY,
	AREA,
	NAVIGATION,
	OCCLUDER,
	LINE,
	PATH,
	POLYGON,
	INSTANCE,
	PARALLAX,
	UNKNOWN
}


func custom_compare(a: Dictionary, b: Dictionary):
	return a["sourceId"] < b["sourceId"]


func set_use_default_filter(value: bool):
	_use_default_filter = value


func set_add_class_as_metadata(value: bool):
	_add_class_as_metadata = value


func set_add_id_as_metadata(value: bool):
	_add_id_as_metadata = value
	

func set_no_alternative_tiles(value: bool):
	_dont_use_alternative_tiles = value


func set_map_wangset_to_terrain(value: bool):
	_map_wangset_to_terrain = value


func set_custom_data_prefix(value: String):
	_custom_data_prefix = value


func set_custom_types(ct: CustomTypes):
	_ct = ct


func set_save_tileset_to(path: String):
	_tileset_save_path = path


func get_tileset():
	return _tileset


static func recursively_change_owner(node: Node, new_owner: Node):
	if node != new_owner:
		node.owner = new_owner
	if node.get_child_count() <= 0: return
	for child in node.get_children():
		recursively_change_owner(child, new_owner)


func create(source_file: String):
	_godot_version = Engine.get_version_info()["hex"]
	_base_path = source_file.get_base_dir()
	var map_content = DataLoader.get_tiled_file_content(source_file, _base_path)
	if map_content == null:
		printerr("FATAL ERROR: Tiled map file '" + source_file + "' not found.")
		return null
	_base_dictionary = preload("DictionaryBuilder.gd").new().get_dictionary(map_content, source_file)
	_map_orientation = _base_dictionary.get("orientation", "othogonal")
	_map_width = _base_dictionary.get("width", 0)
	_map_height = _base_dictionary.get("height", 0)
	_map_tile_width = _base_dictionary.get("tilewidth", 0)
	_map_tile_height = _base_dictionary.get("tileheight", 0)
	_infinite = _base_dictionary.get("infinite", false)
	_parallax_origin_x = _base_dictionary.get("parallaxoriginx", 0)
	_parallax_origin_y = _base_dictionary.get("parallaxoriginy", 0)
	_background_color = _base_dictionary.get("backgroundcolor", "")

	if _ct != null:
		_ct.merge_custom_properties(_base_dictionary, "map")

	if _base_dictionary.has("tilesets"):
		var tilesets = _base_dictionary["tilesets"]
		for tileSet in tilesets:
			_first_gids.append(int(tileSet["firstgid"]))
		var tileset_creator = preload("TilesetCreator.gd").new()
		tileset_creator.set_base_path(source_file)
		tileset_creator.set_map_parameters(Vector2i(_map_tile_width, _map_tile_height))
		if _ct != null:
			tileset_creator.set_custom_types(_ct)	
		if _map_wangset_to_terrain:
			tileset_creator.map_wangset_to_terrain()
		tileset_creator.set_custom_data_prefix(_custom_data_prefix)
		_tileset = tileset_creator.create_from_dictionary_array(tilesets)
		_atlas_sources = tileset_creator.get_registered_atlas_sources()
		if _atlas_sources != null:
			_atlas_sources.sort_custom(custom_compare)
		_object_groups = tileset_creator.get_registered_object_groups()
	if _tileset == null:
		# If tileset still null create an empty one
		_tileset = TileSet.new()
	_tileset.tile_size = Vector2i(_map_tile_width, _map_tile_height)
	match _map_orientation:
		"isometric":
			_tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
			_tileset.tile_layout = TileSet.TILE_LAYOUT_DIAMOND_DOWN
		"staggered":
			var stagger_axis = _base_dictionary.get("staggeraxis", "y")
			var stagger_index = _base_dictionary.get("staggerindex", "odd")
			_tileset.tile_shape = TileSet.TILE_SHAPE_ISOMETRIC
			_tileset.tile_layout = TileSet.TILE_LAYOUT_STACKED if stagger_index == "odd" else TileSet.TILE_LAYOUT_STACKED_OFFSET
			_tileset.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL if stagger_axis == "x" else TileSet.TILE_OFFSET_AXIS_HORIZONTAL
		"hexagonal":
			var stagger_axis = _base_dictionary.get("staggeraxis", "y")
			var stagger_index = _base_dictionary.get("staggerindex", "odd")
			_tileset.tile_shape = TileSet.TILE_SHAPE_HEXAGON
			_tileset.tile_layout = TileSet.TILE_LAYOUT_STACKED if stagger_index == "odd" else TileSet.TILE_LAYOUT_STACKED_OFFSET
			_tileset.tile_offset_axis = TileSet.TILE_OFFSET_AXIS_VERTICAL if stagger_axis == "x" else TileSet.TILE_OFFSET_AXIS_HORIZONTAL
	
	_base_node = Node2D.new()
	_base_name = source_file.get_file().get_basename()
	_base_node.name = _base_name
	_parallax_background = ParallaxBackground.new()
	_base_node.add_child(_parallax_background)
	_parallax_background.name = _base_name + " (PBG)"
	_parallax_background.owner = _base_node
	if _background_color != "":
		_background = ColorRect.new()
		_background.color = Color(_background_color)
		_background.size = Vector2(_map_width * _map_tile_width, _map_height * _map_tile_height)
		_base_node.add_child(_background)
		_background.name = BACKGROUND_COLOR_RECT_NAME
		_background.owner = _base_node
	
	if _base_dictionary.has("layers"):
		for layer in _base_dictionary["layers"]:
			handle_layer(layer, _base_node)

	if _tileset_save_path != "":
		var save_ret = ResourceSaver.save(_tileset, _tileset_save_path)
		if save_ret == OK:
			print("Successfully saved tileset to '" + _tileset_save_path + "'")
			for node in _base_node.find_children("*", "TileMapLayer"):
				if node is TileMapLayer and node.tile_set.resource_path == "":
					node.tile_set = ResourceLoader.load(_tileset_save_path)
		else:
			printerr("Saving tileset returned error " + str(save_ret))
			CommonUtils.error_count += 1


	if _base_dictionary.has("properties"):
		handle_properties(_base_node, _base_dictionary["properties"])

	if _parallax_background.get_child_count() == 0:
		_base_node.remove_child(_parallax_background)
		_parallax_background.queue_free()

	# Remove internal helper custom data
	if _tileset.get_custom_data_layers_count() > 0:
		_tileset.remove_custom_data_layer(0)

	if _base_node.get_child_count() > 1: return _base_node

	var ret = _base_node.get_child(0)
	recursively_change_owner(ret, ret)
	if _base_dictionary.has("properties"):
		handle_properties(ret, _base_dictionary["properties"])
	ret.name = _base_name
	return ret


func handle_layer(layer: Dictionary, parent: Node2D):
	var layer_offset_x = layer.get("offsetx", 0)
	var layer_offset_y = layer.get("offsety", 0)
	var layer_opacity = layer.get("opacity", 1.0)
	var layer_visible = layer.get("visible", true)
	_encoding = layer.get("encoding", "csv")
	_compression = layer.get("compression", "")
	var layer_type = layer.get("type", "tilelayer")
	var tint_color = layer.get("tintcolor", "#ffffff")

	if _ct != null:
		_ct.merge_custom_properties(layer, "layer")

	# v1.2: Skip layer
	if str(get_property(layer, "no_import", "bool")) == "true":
		return

	if layer_type == "tilelayer":
		if _map_orientation == "isometric":
			layer_offset_x += _map_tile_width * (_map_height / 2.0 - 0.5)
		var layer_name = str(layer["name"])
		_tilemap_layer = TileMapLayer.new()
		if layer_name != "":
			_tilemap_layer.name = layer_name
		_tilemap_layer.visible = layer_visible
		_tilemap_layer.position = Vector2(layer_offset_x, layer_offset_y)
		if layer_opacity < 1.0 or tint_color != "#ffffff":
			_tilemap_layer.modulate = Color(tint_color, layer_opacity)
		_tilemap_layer.tile_set = _tileset
		# Leave the old handling for the time being
		handle_parallaxes(parent, _tilemap_layer, layer)
		if _map_orientation == "isometric" or _map_orientation == "staggered":
			_tilemap_layer.y_sort_enabled = true

		if not _use_default_filter:
			_tilemap_layer.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		
		if _infinite and layer.has("chunks"):
			# Chunks
			for chunk in layer["chunks"]:
				var offset_x = int(chunk["x"])
				var offset_y = int(chunk["y"])
				var chunk_width = int(chunk["width"])
				var chunk_height = int(chunk["height"])
				var chunk_data = handle_data(chunk["data"], chunk_width * chunk_height)
				if chunk_data != null:
					create_map_from_data(chunk_data, offset_x, offset_y, chunk_width)

		elif layer.has("data"):
			# Data
			var data = handle_data(layer["data"], _map_width * _map_height)
			if data != null:
				create_map_from_data(data, 0, 0, _map_width)

		var class_string = layer.get("class", "")
		if class_string == "":
			class_string = layer.get("type", "")
		if _add_class_as_metadata and class_string != "":
			_tilemap_layer.set_meta("class", class_string)
		var obj_id = layer.get("id", 0)
		if _add_id_as_metadata and obj_id != 0:
			_tilemap_layer.set_meta("id", obj_id)

		if layer.has("properties"):
			handle_properties(_tilemap_layer, layer["properties"])

	elif layer_type == "objectgroup":
		var node_type = get_godot_node_type(layer)

		var layer_node
		if node_type == _godot_type.PARALLAX:
			layer_node = Parallax2D.new()
			parent.add_child(layer_node)
			layer_node.owner = _base_node
			if layer.has("parallaxx") or layer.has("parallaxy"):
				var par_x = layer.get("parallaxx", 1.0)
				var par_y = layer.get("parallaxy", 1.0)
				layer_node.scroll_scale = Vector2(par_x, par_y)
		else:
			layer_node = Node2D.new()
			# Leave the old handling for the time being
			handle_parallaxes(parent, layer_node, layer)
		
		if "name" in layer:
			layer_node.name = layer["name"]
		if layer_opacity < 1.0 or tint_color != "#ffffff":
			layer_node.modulate = Color(tint_color, layer_opacity)
		layer_node.visible = layer.get("visible", true)
		var layer_pos_x = layer.get("x", 0.0)
		var layer_pos_y = layer.get("y", 0.0)
		layer_node.position = Vector2(layer_pos_x + layer_offset_x, layer_pos_y + layer_offset_y)
		if not _use_default_filter:
			layer_node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		if _map_orientation == "isometric" or _map_orientation == "staggered":
			layer_node.y_sort_enabled = true

		if layer.has("objects"):
			for obj in layer["objects"]:
				handle_object(obj, layer_node, _tileset, Vector2.ZERO)

		if layer.has("properties"):
			handle_properties(layer_node, layer["properties"])

	elif layer_type == "group":
		var node_type = get_godot_node_type(layer)

		var group_node
		if node_type == _godot_type.PARALLAX:
			group_node = Parallax2D.new()
			parent.add_child(group_node)
			group_node.owner = _base_node
			if layer.has("parallaxx") or layer.has("parallaxy"):
				var par_x = layer.get("parallaxx", 1.0)
				var par_y = layer.get("parallaxy", 1.0)
				group_node.scroll_scale = Vector2(par_x, par_y)
		else:
			group_node = Node2D.new()
			# Leave the old handling for the time being
			handle_parallaxes(parent, group_node, layer)

		group_node.name = layer.get("name", "group")
		if layer_opacity < 1.0 or tint_color != "#ffffff":
			group_node.modulate = Color(tint_color, layer_opacity)
		group_node.visible = layer.get("visible", true)
		var layer_pos_x = layer.get("x", 0.0)
		var layer_pos_y = layer.get("y", 0.0)
		group_node.position = Vector2(layer_pos_x + layer_offset_x, layer_pos_y + layer_offset_y)
	
		if layer.has("layers"):
			for child_layer in layer["layers"]:
				handle_layer(child_layer, group_node)

		if layer.has("properties"):
			handle_properties(group_node, layer["properties"])

	elif layer_type == "imagelayer":
		var node_type = get_godot_node_type(layer)

		if node_type == _godot_type.PARALLAX:
			var px_2d = Parallax2D.new()
			parent.add_child(px_2d)
			px_2d.owner = _base_node
			px_2d.name = layer.get("name", "parallax")
			if layer.has("parallaxx") or layer.has("parallaxy"):
				var par_x = layer.get("parallaxx", 1.0)
				var par_y = layer.get("parallaxy", 1.0)
				px_2d.scroll_scale = Vector2(par_x, par_y)
			if layer.has("repeatx") and layer["repeatx"] == 1:
				var repeat_size_x = layer.get("imagewidth", 0)
				if repeat_size_x > 0:
					px_2d.repeat_size = Vector2(repeat_size_x, px_2d.repeat_size.y)
					px_2d.repeat_times = 2
			if layer.has("repeaty") and layer["repeaty"] == 1:
				var repeat_size_y = layer.get("imageheight", 0)
				if repeat_size_y > 0:
					px_2d.repeat_size = Vector2(px_2d.repeat_size.x, repeat_size_y)
					px_2d.repeat_times = 2
			var texture_rect = TextureRect.new()
			texture_rect.name = layer["image"].get_file().get_basename()
			texture_rect.position = Vector2(layer_offset_x, layer_offset_y)
			var imagewidth = layer.get("imagewidth", 0)
			var imageheight = layer.get("imageheight", 0)
			texture_rect.size = Vector2(imagewidth, imageheight)
			if layer_opacity < 1.0 or tint_color != "#ffffff":
				texture_rect.modulate = Color(tint_color, layer_opacity)
			texture_rect.visible = layer_visible
			texture_rect.texture = DataLoader.load_image(layer["image"], _base_path)

			px_2d.add_child(texture_rect)
			texture_rect.owner = _base_node

			if layer.has("properties"):
				handle_properties(px_2d, layer["properties"])
		else:
			var texture_rect = TextureRect.new()
			handle_parallaxes(parent, texture_rect, layer)

			texture_rect.name = layer.get("name", "image")
			texture_rect.position = Vector2(layer_offset_x, layer_offset_y)

			var imagewidth = layer.get("imagewidth", 0)
			var imageheight = layer.get("imageheight", 0)
			texture_rect.size = Vector2(imagewidth, imageheight)
			if layer_opacity < 1.0 or tint_color != "#ffffff":
				texture_rect.modulate = Color(tint_color, layer_opacity)
			texture_rect.visible = layer_visible
			texture_rect.texture = DataLoader.load_image(layer["image"], _base_path)

			if layer.has("properties"):
				handle_properties(texture_rect, layer["properties"])

func handle_parallaxes(parent: Node, layer_node: Node, layer_dict: Dictionary):
	if layer_dict.has("parallaxx") or layer_dict.has("parallaxy"):
		if not _parallax_layer_existing:
			if _background != null:
				_background.owner = null
				_background.reparent(_parallax_background)
				_background.owner = _base_node
			_parallax_layer_existing = true
	
		var par_x = layer_dict.get("parallaxx", 0.0)
		var par_y = layer_dict.get("parallaxy", 0.0)
		var parallax_node = ParallaxLayer.new()
		_parallax_background.add_child(parallax_node)
		parallax_node.owner = _base_node
		var px_name = layer_dict.get("name", "")
		parallax_node.name = px_name + " (PL)" if px_name != "" else "ParallaxLayer"
		parallax_node.motion_scale = Vector2(par_x, par_y)
		var mirror_x = layer_dict.get("imagewidth", 0) if layer_dict.get("repeatx", 0) else 0
		var mirror_y = layer_dict.get("imageheight", 0) if layer_dict.get("repeaty", 0) else 0
		if mirror_x != 0 or mirror_y != 0:
			parallax_node.motion_mirroring = Vector2(mirror_x, mirror_y)
		parallax_node.add_child(layer_node)
	else:
		parent.add_child(layer_node)

	layer_node.owner = _base_node


func handle_data(data, map_size):
	var ret: Array = []
	match _encoding:
		"csv":
			for cell in data:
				ret.append(cell)
		"base64":
			var bytes = Marshalls.base64_to_raw(data)
			if _compression != "":
				match _compression:
					"gzip":
						ret = bytes.decompress(map_size * 4, FileAccess.COMPRESSION_GZIP)
					"zlib":
						ret = bytes.decompress(map_size * 4, FileAccess.COMPRESSION_DEFLATE)
					"zstd":
						ret = bytes.decompress(map_size * 4, FileAccess.COMPRESSION_ZSTD)
					_:
						printerr("Decompression for type '" + _compression + "' not yet implemented.")
						CommonUtils.error_count += 1
						return []
				bytes = PackedByteArray(ret)
			ret = bytes.to_int32_array()	
	return ret


func create_polygons_on_alternative_tiles(source_data: TileData, target_data: TileData, alt_id: int):
	var flipped_h = (alt_id & 1) > 0
	var flipped_v = (alt_id & 2) > 0
	var flipped_d = (alt_id & 4) > 0
	var origin = Vector2(source_data.texture_origin)
	var physics_layers_count = _tileset.get_physics_layers_count()
	for layer_id in range(physics_layers_count):
		var collision_polygons_count = source_data.get_collision_polygons_count(layer_id)
		for polygon_id in range(collision_polygons_count):
			var pts = source_data.get_collision_polygon_points(layer_id, polygon_id)
			var pts_new: PackedVector2Array
			var i = 0
			for pt in pts:
				pts_new.append(pt+origin)
				if flipped_d:
					var tmp = pts_new[i].x
					pts_new[i].x = pts_new[i].y
					pts_new[i].y = tmp
				if flipped_h:
					pts_new[i].x = -pts_new[i].x
				if flipped_v:
					pts_new[i].y = -pts_new[i].y
				pts_new[i] -= Vector2(target_data.texture_origin)
				i += 1
			target_data.add_collision_polygon(layer_id)
			target_data.set_collision_polygon_points(layer_id, polygon_id, pts_new)
	var navigation_layers_count = _tileset.get_navigation_layers_count()
	for layer_id in range(navigation_layers_count):
		var nav_p = source_data.get_navigation_polygon(layer_id)
		if nav_p == null: continue
		var pts = nav_p.get_outline(0)
		var pts_new: PackedVector2Array
		var i = 0
		for pt in pts:
			pts_new.append(pt+origin)
			if flipped_d:
				var tmp = pts_new[i].x
				pts_new[i].x = pts_new[i].y
				pts_new[i].y = tmp
			if flipped_h:
				pts_new[i].x = -pts_new[i].x
			if flipped_v:
				pts_new[i].y = -pts_new[i].y
			pts_new[i] -= Vector2(target_data.texture_origin)
			i += 1
		var navigation_polygon = NavigationPolygon.new()
		navigation_polygon.add_outline(pts_new)
		#navigation_polygon.make_polygons_from_outlines()
		# Replaced in 4.2 deprecated function make_polygons_from_outlines
		navigation_polygon.vertices = pts_new
		var polygon = PackedInt32Array()
		for idx in range(navigation_polygon.vertices.size()):
			polygon.push_back(idx)
		navigation_polygon.add_polygon(polygon)
		target_data.set_navigation_polygon(layer_id, navigation_polygon)
	var occlusion_layers_count = _tileset.get_occlusion_layers_count()
	for layer_id in range(occlusion_layers_count):
		var occ: OccluderPolygon2D
		if _godot_version >= 0x040400:
			var occ_count = source_data.get_occluder_polygons_count(layer_id)
			if occ_count == 0: continue
			occ = source_data.get_occluder_polygon(layer_id, 0)
		else:
			occ = source_data.get_occluder(layer_id)
			if occ == null: continue
		var pts = occ.polygon
		var pts_new: PackedVector2Array
		var i = 0
		for pt in pts:
			pts_new.append(pt+origin)
			if flipped_d:
				var tmp = pts_new[i].x
				pts_new[i].x = pts_new[i].y
				pts_new[i].y = tmp
			if flipped_h:
				pts_new[i].x = -pts_new[i].x
			if flipped_v:
				pts_new[i].y = -pts_new[i].y
			pts_new[i] -= Vector2(target_data.texture_origin)
			i += 1
		var occluder_polygon = OccluderPolygon2D.new()
		occluder_polygon.polygon = pts_new
		if _godot_version >= 0x040400:
			target_data.set_occluder_polygons_count(layer_id, 1)
			target_data.set_occluder_polygon(layer_id, 0, occluder_polygon)
		else:
			target_data.set_occluder(layer_id, occluder_polygon)
		

func create_map_from_data(layer_data: Array, offset_x: int, offset_y: int, map_width: int):
	var cell_counter: int = -1
	for cell in layer_data:
		cell_counter += 1
		var int_id: int = int(cell) & 0xFFFFFFFF
		var flipped_h = (int_id & FLIPPED_HORIZONTALLY_FLAG) > 0
		var flipped_v = (int_id & FLIPPED_VERTICALLY_FLAG) > 0
		var flipped_d = (int_id & FLIPPED_DIAGONALLY_FLAG) > 0
		var gid: int = int_id & 0x0FFFFFFF
		if gid <= 0: continue
		@warning_ignore("integer_division")
		var cell_coords = Vector2(cell_counter % map_width + offset_x, cell_counter / map_width + offset_y)

		var source_id = get_matching_source_id(gid)
		# Should not be the case, but who knows...
		if source_id < 0: continue

		var tile_offset = get_tile_offset(gid)
		var tile_shader_material = get_tileset_shader_material(gid)

		var atlas_source
		if _tileset.has_source(source_id):
			atlas_source = _tileset.get_source(source_id)
		else: continue
		var atlas_width: int = atlas_source.get_atlas_grid_size().x
		if atlas_width <= 0: continue

		var effective_gid: int = gid - _first_gids[get_first_gid_index(gid)]
		var atlas_coords = Vector2i.ZERO
		if get_num_tiles_for_source_id(source_id) > 1:
			if atlas_source.get_atlas_grid_size() == Vector2i.ONE:
				atlas_coords = Vector2i.ZERO
			else:
				@warning_ignore("integer_division")
				atlas_coords = Vector2(effective_gid % atlas_width, effective_gid / atlas_width)
		if not atlas_source.has_tile(atlas_coords):
			atlas_source.create_tile(atlas_coords)
			var current_tile = atlas_source.get_tile_data(atlas_coords, 0)
			var tile_size = atlas_source.texture_region_size
			if tile_size.x != _map_tile_width or tile_size.y != _map_tile_height:
				var diff_x = tile_size.x - _map_tile_width
				if diff_x % 2 != 0:
					diff_x -= 1
				var diff_y = tile_size.y - _map_tile_height
				if diff_y % 2 != 0:
					diff_y += 1
				current_tile.texture_origin = Vector2i(-diff_x/2, diff_y/2) - tile_offset

			if tile_shader_material != null:
				current_tile.material = tile_shader_material

		var alt_id = 0
		if flipped_h or flipped_v or flipped_d:
			if _dont_use_alternative_tiles and _godot_version >= 0x40200:
				if flipped_h:
					alt_id |= TileSetAtlasSource.TRANSFORM_FLIP_H
				if flipped_v:
					alt_id |= TileSetAtlasSource.TRANSFORM_FLIP_V
				if flipped_d:
					alt_id |= TileSetAtlasSource.TRANSFORM_TRANSPOSE
			else:
				alt_id = (1 if flipped_h else 0) + (2 if flipped_v else 0) + (4 if flipped_d else 0)
				if not atlas_source.has_alternative_tile(atlas_coords, alt_id):
					atlas_source.create_alternative_tile(atlas_coords, alt_id)
					var tile_data = atlas_source.get_tile_data(atlas_coords, alt_id)
					tile_data.flip_h = flipped_h
					tile_data.flip_v = flipped_v
					tile_data.transpose = flipped_d
					var tile_size = atlas_source.texture_region_size
					if flipped_d:
						tile_size = Vector2i(tile_size.y, tile_size.x)
					if tile_size.x != _map_tile_width or tile_size.y != _map_tile_height:
						var diff_x = tile_size.x - _map_tile_width
						if diff_x % 2 != 0:
							diff_x -= 1
						var diff_y = tile_size.y - _map_tile_height
						if diff_y % 2 != 0:
							diff_y += 1
						tile_data.texture_origin = Vector2i(-diff_x/2, diff_y/2)
					tile_data.texture_origin -= tile_offset
					
					if tile_shader_material != null:
						tile_data.material = tile_shader_material
					
					var src_data = atlas_source.get_tile_data(atlas_coords, 0)
					create_polygons_on_alternative_tiles(src_data, tile_data, alt_id)
					# Copy metadata to alternative tile
					for meta_name in src_data.get_meta_list():
						tile_data.set_meta(meta_name, src_data.get_meta(meta_name))
		
		_tilemap_layer.set_cell(cell_coords, source_id, atlas_coords, alt_id)


static func get_godot_type(godot_type_string: String):
	var gts = godot_type_string.to_lower()
	var godot_type = {
		"": _godot_type.EMPTY,
		"collision": _godot_type.BODY,
		"staticbody": _godot_type.BODY,
		"characterbody": _godot_type.CBODY,
		"rigidbody": _godot_type.RBODY,
		"animatablebody": _godot_type.ABODY,
		"area": _godot_type.AREA,
		"navigation": _godot_type.NAVIGATION,
		"occluder": _godot_type.OCCLUDER,
		"line": _godot_type.LINE,
		"path": _godot_type.PATH,
		"polygon": _godot_type.POLYGON,
		"instance": _godot_type.INSTANCE,
		"parallax": _godot_type.PARALLAX
	}.get(gts, _godot_type.UNKNOWN)
	return godot_type


static func get_godot_node_type_property(obj: Dictionary):
	var ret = ""
	var property_found = false
	if obj.has("properties"):
		for property in obj["properties"]:
			var name: String = property.get("name", "")
			var type: String = property.get("type", "string")
			var val: String = str(property.get("value", ""))
			if name.to_lower() == GODOT_NODE_TYPE_PROPERTY and type == "string":
				property_found = true
				ret = val
				break
	return [ret, property_found]


static func get_godot_node_type(obj: Dictionary):
	var class_string = obj.get("class", "")
	if class_string == "":
		class_string = obj.get("type", "")
	var search_result = get_godot_node_type_property(obj)
	var godot_node_type_property_string = search_result[0]
	var godot_node_type_prop_found = search_result[1]
	if not godot_node_type_prop_found:
		godot_node_type_property_string = class_string
	return get_godot_type(godot_node_type_property_string)


static func set_sprite_offset(obj_sprite: Sprite2D, width: float, height: float, alignment: String):
	obj_sprite.offset = {
		"bottomleft": Vector2(width / 2.0, -height / 2.0),
		"bottom": Vector2(0.0, -height / 2.0),
		"bottomright": Vector2(-width / 2.0, -height / 2.0),
		"left": Vector2(width / 2.0, 0.0),
		"center": Vector2(0.0, 0.0),
		"right": Vector2(-width / 2.0, 0.0),
		"topleft": Vector2(width / 2.0, height / 2.0),
		"top": Vector2(0.0, height / 2.0),
		"topright": Vector2(-width / 2.0, height / 2.0),
	}.get(alignment, Vector2(width / 2.0, -height / 2.0))


static func get_instance_offset(width: float, height: float, r_alignment: String, c_alignment: String) -> Vector2:
	var centered_alignment = {
		"bottomleft": Vector2(width / 2.0, -height / 2.0),
		"bottom": Vector2(0.0, -height / 2.0),
		"bottomright": Vector2(-width / 2.0, -height / 2.0),
		"left": Vector2(width / 2.0, 0.0),
		"center": Vector2.ZERO,
		"right": Vector2(-width / 2.0, 0.0),
		"topleft": Vector2(width / 2.0, height / 2.0),
		"top": Vector2(0.0, height / 2.0),
		"topright": Vector2(-width / 2.0, height / 2.0),
	}.get(c_alignment, Vector2.ZERO)
	return centered_alignment + {
		"bottomleft": Vector2(-width / 2.0, height / 2.0),
		"bottom": Vector2(0.0, height / 2.0),
		"bottomright": Vector2(width / 2.0, height / 2.0),
		"left": Vector2(-width / 2.0, 0.0),
		"center": Vector2.ZERO,
		"right": Vector2(width / 2.0, 0.0),
		"topleft": Vector2(-width / 2.0, -height / 2.0),
		"top": Vector2(0.0, -height / 2.0),
		"topright": Vector2(width / 2.0, -height / 2.0),
	}.get(r_alignment, Vector2.ZERO)


static func get_position_offset(width: float, height: float, rotation: float) -> Vector2:
	var orig_point = Vector2(-width / 2.0, -height / 2.0)
	var rot_rad = rotation * PI / 180.0
	var new_point = orig_point.rotated(rot_rad)
	return orig_point - new_point


func convert_metadata_to_obj_properties(td: TileData, obj: Dictionary) -> void:
	var meta_list = td.get_meta_list()
	for meta_name in meta_list:
		if meta_name.to_lower() == GODOT_NODE_TYPE_PROPERTY:
			continue
		if meta_name.to_lower() == CLASS_INTERNAL and not _add_class_as_metadata:
			continue
		var meta_val = td.get_meta(meta_name)
		var meta_type = typeof(meta_val)
		var prop_dict = {}
		prop_dict["name"] = meta_name
		var prop_type = {
			TYPE_BOOL: "bool",
			TYPE_INT: "int",
			TYPE_STRING: "string",
			TYPE_FLOAT: "float",
			TYPE_COLOR: "color"
		}.get(meta_type, "string")
		# Type "file" assumed and thus forced for these properties
		if meta_name.to_lower() in ["godot_script", "material", "physics_material_override"]:
			prop_type = "file"

		prop_dict["type"] = prop_type
		prop_dict["value"] = meta_val

		if obj.has("properties"):
			# Add property only if not already contained in properties
			var found = false
			for prop in obj["properties"]:
				if prop["name"].to_lower() == meta_name.to_lower():
					found = true
			if not found:
				obj["properties"].append(prop_dict)
		else:
			obj["properties"] = [prop_dict]


func handle_object(obj: Dictionary, layer_node: Node, tileset: TileSet, offset: Vector2) -> void:
	var previous_count := layer_node.get_child_count()
	var authored_name := str(obj.get("name", ""))
	_create_object(obj, layer_node, tileset, offset)
	for index in range(previous_count, layer_node.get_child_count()):
		# Generated names (e.g. "point") are not authored Tiled names. Keep
		# that distinction when a post-processor replaces this placeholder.
		layer_node.get_child(index).set_meta("tiled_object_name", authored_name)

func _create_object(obj: Dictionary, layer_node: Node, tileset: TileSet, offset: Vector2) -> void:
	var obj_id = obj.get("id", 0)
	var obj_x = obj.get("x", offset.x)
	var obj_y = obj.get("y", offset.y)
	var obj_rot = obj.get("rotation", 0.0)
	var obj_width = obj.get("width", 0.0)
	var obj_height = obj.get("height", 0.0)
	var obj_visible = obj.get("visible", true)
	var obj_name = str(obj.get("name", ""))

	if _ct != null:
		_ct.merge_custom_properties(obj, "object")

	var class_string = obj.get("class", "")
	if class_string == "":
		class_string = obj.get("type", "")
	var search_result = get_godot_node_type_property(obj)
	var godot_node_type_property_string = search_result[0]
	var godot_node_type_prop_found = search_result[1]
	if not godot_node_type_prop_found:
		godot_node_type_property_string = class_string
	var godot_type = get_godot_type(godot_node_type_property_string)

	if godot_type == _godot_type.UNKNOWN:
		if not _add_class_as_metadata and class_string != "" and not godot_node_type_prop_found:
			print_rich("[color=" + WARNING_COLOR +"] -- Unknown class '" + class_string + "'. -> Assuming Default[/color]")
			CommonUtils.warning_count += 1
		elif godot_node_type_prop_found and godot_node_type_property_string != "":	
			print_rich("[color=" + WARNING_COLOR +"] -- Unknown " + GODOT_NODE_TYPE_PROPERTY + " '" + godot_node_type_property_string + "'. -> Assuming Default[/color]")
			CommonUtils.warning_count += 1
		godot_type = _godot_type.BODY


	if obj.has("template"):
		var template_dict: Dictionary
		var template_file = obj["template"]
		var template_file_full_path = _base_path.path_join(template_file)
		var template_content = DataLoader.get_tiled_file_content(template_file, _base_path)
		if template_content == null:
			printerr("ERROR: Template file '" + template_file + "' not found. -> Continuing but result may be unusable")
			CommonUtils.error_count += 1
			template_dict = {}
		else:
			template_dict = preload("DictionaryBuilder.gd").new().get_dictionary(template_content, template_file)

		var template_tileset = null
		if template_dict.has("tilesets"):
			var tilesets = template_dict["tilesets"]
			var tileset_creator = preload("TilesetCreator.gd").new()
			tileset_creator.set_base_path(template_file_full_path)
			tileset_creator.set_map_parameters(Vector2i(_map_tile_width, _map_tile_height))
			if _map_wangset_to_terrain:
				tileset_creator.map_wangset_to_terrain()
			template_tileset = tileset_creator.create_from_dictionary_array(tilesets)

		if template_dict.has("objects"):
			for template_obj in template_dict["objects"]:
				template_obj["template_dir_path"] = template_file_full_path.get_base_dir()

				# v1.5.3 Fix according to Carlo M (dogezen)
				# override and merge properties defined in obj with properties defined in template
				# since obj may override and define additional properties to those defined in template
				if obj.has("properties"):
					if template_obj.has("properties"):
						# merge obj properties that may have been overridden in the obj instance
						# and add any additional properties defined in instanced obj that are 
						# not defined in template
						for prop in obj["properties"]:
							var found = false
							for templ_prop in template_obj["properties"]:
								if prop.name == templ_prop.name:
									templ_prop.value = prop.value
									found = true
									break
							if not found:
								template_obj["properties"].append(prop)
					else:
						# template comes without properties, since obj has properties
						# then merge them into the template
						template_obj["properties"] = obj.properties

				# Template obj needs id and obj class/type/name overrides template's class/type/name
				template_obj["id"] = obj_id
				if obj.has("class") and obj["class"] != "":
					template_obj["class"] = obj["class"]
				if obj.has("type") and obj["type"] != "":
					template_obj["type"] = obj["type"]
				if obj.has("name") and obj["name"] != "":
					template_obj["name"] = obj["name"]

				handle_object(template_obj, layer_node, template_tileset, Vector2(obj_x, obj_y))

	# v1.2: New class 'instance'
	if godot_type == _godot_type.INSTANCE and not obj.has("template") and not obj.has("text") and not obj.has("gid"):
		var res_path = get_property(obj, "res_path", "file")
		if res_path == "":
			printerr("Object of class 'instance': Mandatory file property 'res_path' not found or invalid. -> Skipped")
			CommonUtils.error_count += 1
		else:
			if obj.has("template_dir_path"):
				res_path = obj.template_dir_path.path_join(res_path)
			var scene = DataLoader.load_resource_from_file(res_path, _base_path)
			# Error check
			if scene == null: return
			var instance = scene.instantiate()
			layer_node.add_child(instance)
			instance.owner = _base_node
			instance.name = obj_name if obj_name != "" else res_path.get_file().get_basename()
			instance.position = transpose_coords(obj_x, obj_y)
			instance.rotation_degrees = obj_rot
			instance.visible = obj_visible
			if _add_class_as_metadata and class_string != "":
				instance.set_meta("class", class_string)
			if _add_id_as_metadata and obj_id != 0:
				instance.set_meta("id", obj_id)
			if obj.has("properties"):
				handle_properties(instance, obj["properties"])
		return

	if obj.has("gid"):
		# gid refers to a tile in a tile set and object is created as sprite
		var int_id: int = obj["gid"]
		var flippedH = (int_id & FLIPPED_HORIZONTALLY_FLAG) > 0
		var flippedV = (int_id & FLIPPED_VERTICALLY_FLAG) > 0
		var gid: int = int_id & 0x0FFFFFFF

		var source_id = get_matching_source_id(gid)
		# Should not be the case, but who knows...
		if source_id < 0: return

		var tile_offset = get_tile_offset(gid)
		_current_tileset_orientation = get_tileset_orientation(gid)
		_current_object_alignment = get_tileset_alignment(gid)
		if _current_object_alignment == DEFAULT_ALIGNMENT:
			_current_object_alignment = "bottomleft" if _map_orientation == "orthogonal" else "bottom"

		if not tileset.has_source(source_id):
			printerr("Could not get AtlasSource with id " + source_id + ". -> Skipped")
			CommonUtils.error_count += 1
			return
	
		var gid_source = tileset.get_source(source_id)
		var obj_sprite = Sprite2D.new()
		layer_node.add_child(obj_sprite)
		obj_sprite.owner = _base_node
		obj_sprite.name = obj_name if obj_name != "" \
							else gid_source.resource_name if gid_source.resource_name != "" \
							else gid_source.texture.resource_path.get_file().get_basename() + "_tile"
		obj_sprite.position = transpose_coords(obj_x, obj_y) + Vector2(tile_offset)
		obj_sprite.texture = gid_source.texture
		obj_sprite.rotation_degrees = obj_rot
		obj_sprite.visible = obj_visible
		var td
		if is_partitioned_tileset(source_id):
			# Object is tile from partitioned tileset 
			var atlas_width: int = gid_source.get_atlas_grid_size().x

			# Can be zero if tileset had an error
			if atlas_width <= 0: return

			var effective_gid: int = gid - _first_gids[get_first_gid_index(gid)]
			@warning_ignore("integer_division")
			var atlas_coords = Vector2(effective_gid % atlas_width, effective_gid / atlas_width)
			if not gid_source.has_tile(atlas_coords):
				gid_source.create_tile(atlas_coords)
			td = gid_source.get_tile_data(atlas_coords, 0)
			obj_sprite.region_enabled = true
			var region_size = Vector2(gid_source.texture_region_size)
			var separation = Vector2(gid_source.separation)
			var margins = Vector2(gid_source.margins)
			var pos: Vector2 = atlas_coords * (region_size + separation) + margins
			if get_property(obj, "clip_artifacts", "bool") == "true":
				pos += Vector2(0.5, 0.5)
				region_size -= Vector2(1.0, 1.0)
				obj_width -= 1.0
				obj_height -= 1.0
			obj_sprite.region_rect = Rect2(pos, region_size)
			set_sprite_offset(obj_sprite, region_size.x, region_size.y, _current_object_alignment)
			if abs(region_size.x - obj_width) > 0.01 or abs(region_size.y - obj_height) > 0.01:
				var scale_x: float = float(obj_width) / float(region_size.x)
				var scale_y: float = float(obj_height) / float(region_size.y)
				obj_sprite.scale = Vector2(scale_x, scale_y)
		else:
			# Object is single image tile
			var gid_width: int = gid_source.texture_region_size.x
			var gid_height: int = gid_source.texture_region_size.y
			obj_sprite.offset = Vector2(gid_width / 2.0, -gid_height / 2.0)
			set_sprite_offset(obj_sprite, gid_width, gid_height, _current_object_alignment)
			# Tiled sub rects?
			if gid_width != gid_source.texture.get_width() or gid_height != gid_source.texture.get_height():
				obj_sprite.region_enabled = true
				obj_sprite.region_rect = Rect2(gid_source.margins, gid_source.texture_region_size)
			if gid_width != obj_width or gid_height != obj_height:
				var scale_x: float = float(obj_width) / gid_width
				var scale_y: float = float(obj_height) / gid_height
				obj_sprite.scale = Vector2(scale_x, scale_y)
			td = gid_source.get_tile_data(Vector2i.ZERO, 0)

		# Tile objects may already have been classified as instance in the tileset
		var obj_is_instance = godot_type == _godot_type.INSTANCE and not obj.has("template") and not obj.has("text")
		var tile_class = ""
		if td.has_meta(CLASS_INTERNAL):
			tile_class = td.get_meta(CLASS_INTERNAL)
			class_string = tile_class
		if td.has_meta(GODOT_NODE_TYPE_PROPERTY):
			tile_class = td.get_meta(GODOT_NODE_TYPE_PROPERTY)

		if tile_class.to_lower() == "instance" or obj_is_instance:
			var res_path = get_property(obj, "res_path", "file")
			if td.has_meta("res_path"):
				if res_path == "":
					res_path = td.get_meta("res_path")
			if res_path == "":
				printerr("Object of class 'instance': Mandatory file property 'res_path' not found or invalid. -> Skipped")
				CommonUtils.error_count += 1
			else:
				if obj.has("template_dir_path"):
					res_path = obj.template_dir_path.path_join(res_path)
				var scene = DataLoader.load_resource_from_file(res_path, _base_path)
				# Error check
				if scene == null: return

				var res_path_extension = res_path.get_file().get_extension().to_lower()
				var res_alignment = get_property(obj, "res_alignment", "string")

				obj_sprite.owner = null
				layer_node.remove_child(obj_sprite)
				obj_sprite.queue_free()
				var instance = scene.instantiate()
				layer_node.add_child(instance)
				instance.owner = _base_node
				instance.name = obj_name if obj_name != "" else res_path.get_file().get_basename()
				instance.position = transpose_coords(obj_x, obj_y)
				if res_alignment != "":
					instance.position += get_instance_offset(obj_width, obj_height, res_alignment, _current_object_alignment)
				elif res_path_extension == "tmx" or res_path_extension == "tmj":
					instance.position += get_instance_offset(obj_width, obj_height, "topleft", _current_object_alignment)
				instance.rotation_degrees = obj_rot
				instance.visible = obj_visible
				instance.scale = obj_sprite.scale
				convert_metadata_to_obj_properties(td, obj)
				if _add_class_as_metadata and class_string != "":
					instance.set_meta("class", class_string)
				if _add_id_as_metadata and obj_id != 0:
					instance.set_meta("id", obj_id)
				if obj.has("properties"):
					handle_properties(instance, obj["properties"])
			return

		# Tile objects may already have been classified as ...body in the tileset
		if tile_class != "" and godot_type == _godot_type.EMPTY:
			godot_type = get_godot_type(tile_class)

		convert_metadata_to_obj_properties(td, obj)

		var idx = td.get_custom_data(CUSTOM_DATA_INTERNAL)
		if idx > 0:
			# Dictionary values are evaluated eagerly: constructing all five
			# node types here leaks the four unselected physics objects.
			var parent: CollisionObject2D
			match godot_type:
				_godot_type.AREA:
					parent = Area2D.new()
				_godot_type.CBODY:
					parent = CharacterBody2D.new()
				_godot_type.RBODY:
					parent = RigidBody2D.new()
				_godot_type.ABODY:
					parent = AnimatableBody2D.new()
				_godot_type.BODY:
					parent = StaticBody2D.new()
			if parent != null:
				obj_sprite.owner = null
				layer_node.remove_child(obj_sprite)
				layer_node.add_child(parent)
				parent.owner = _base_node
				parent.name = obj_sprite.name
				parent.position = obj_sprite.position
				parent.rotation_degrees = obj_sprite.rotation_degrees
				obj_sprite.position = Vector2.ZERO
				obj_sprite.rotation_degrees = 0.0
				parent.add_child(obj_sprite)
				obj_sprite.owner = _base_node
				add_collision_shapes(parent, get_object_group(idx), obj_width, obj_height, flippedH, flippedV, obj_sprite.scale)
				if obj.has("properties"):
					handle_properties(parent, obj["properties"])
			
		obj_sprite.flip_h = flippedH
		obj_sprite.flip_v = flippedV

		if _add_class_as_metadata and class_string != "":
			obj_sprite.set_meta("class", class_string)
		if _add_id_as_metadata and obj_id != 0:
			obj_sprite.set_meta("id", obj_id)
		if obj.has("properties"):
			handle_properties(obj_sprite, obj["properties"])

	elif obj.has("text"):
		var obj_text = Label.new()
		layer_node.add_child(obj_text)
		obj_text.owner = _base_node
		obj_text.name = obj_name if obj_name != "" else "Text"
		obj_text.position = transpose_coords(obj_x, obj_y)
		obj_text.size = Vector2(obj_width, obj_height)
		obj_text.clip_text = true
		obj_text.rotation_degrees = obj_rot
		obj_text.visible = obj_visible
		var txt = obj["text"]
		obj_text.text = txt.get("text", "Hello World")
		var wrap_ = txt.get("wrap", false)
		obj_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap_ else TextServer.AUTOWRAP_OFF
		var align_h = txt.get("halign", "left")
		match align_h:
			"left": obj_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			"center": obj_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			"right": obj_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			"justify": obj_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_FILL
		var align_v = txt.get("valign", "top")
		match align_v:
			"top": obj_text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
			"center": obj_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			"bottom": obj_text.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		var font_family = txt.get("fontfamily", "Sans-Serif")
		var font = SystemFont.new()
		font.font_names = [font_family]
		font.oversampling = 5.0
		obj_text.add_theme_font_override("font", font)
		obj_text.add_theme_font_size_override("font_size", txt.get("pixelsize", 16))
		obj_text.add_theme_color_override("font_color", Color(txt.get("color", "#000000")))
		if obj.has("properties"):
			handle_properties(obj_text, obj["properties"])

	elif not obj.has("template"):

		if godot_type == _godot_type.EMPTY:
			godot_type = _godot_type.BODY

		var object_base_coords = transpose_coords(obj_x, obj_y)

		if obj.has("point"):
			var marker = Marker2D.new()
			layer_node.add_child(marker)
			marker.owner = _base_node
			marker.name = obj_name if obj_name != "" else "point"
			marker.position = object_base_coords
			marker.rotation_degrees = obj_rot
			marker.visible = obj_visible
			if _add_class_as_metadata and class_string != "":
				marker.set_meta("class", class_string)
			if _add_id_as_metadata and obj_id != 0:
				marker.set_meta("id", obj_id)		
			if obj.has("properties"):
				handle_properties(marker, obj["properties"])
		elif obj.has("polygon"):
			if godot_type == _godot_type.BODY or godot_type == _godot_type.ABODY or godot_type == _godot_type.AREA:
				var co: CollisionObject2D
				if godot_type == _godot_type.AREA:
					co = Area2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (Area)" if obj_name != "" else "Area"
				elif godot_type == _godot_type.ABODY:
					co = AnimatableBody2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (AB)" if obj_name != "" else "AnimatableBody"
				else:
					co = StaticBody2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (SB)" if obj_name != "" else "StaticBody"
				co.owner = _base_node
				co.position = object_base_coords
				co.visible = obj_visible
				var polygon_shape = CollisionPolygon2D.new()
				polygon_shape.polygon = polygon_from_array(obj["polygon"])
				co.add_child(polygon_shape)
				polygon_shape.owner = _base_node
				polygon_shape.name = obj_name if obj_name != "" else "Polygon Shape"
				polygon_shape.position = Vector2.ZERO
				polygon_shape.rotation_degrees = obj_rot
				if _add_class_as_metadata and class_string != "":
					co.set_meta("class", class_string)
				if _add_id_as_metadata and obj_id != 0:
					co.set_meta("id", obj_id)
				if obj.has("properties"):
					handle_properties(co, obj["properties"])
			elif godot_type == _godot_type.NAVIGATION:
				var nav_region = NavigationRegion2D.new()
				layer_node.add_child(nav_region)
				nav_region.owner = _base_node
				nav_region.name = obj_name + " (NR)" if obj_name != "" else "Navigation"
				nav_region.position = object_base_coords
				nav_region.rotation_degrees = obj_rot
				nav_region.visible = obj_visible
				var nav_poly = NavigationPolygon.new()
				nav_region.navigation_polygon = nav_poly
				var pg = polygon_from_array(obj["polygon"])
				nav_poly.add_outline(pg)
				#nav_poly.make_polygons_from_outlines()
				# Replaced in 4.2 deprecated function make_polygons_from_outlines
				nav_poly.vertices = pg
				var polygon = PackedInt32Array()
				for idx in range(nav_poly.vertices.size()):
					polygon.push_back(idx)
				nav_poly.add_polygon(polygon)

				if _add_class_as_metadata and class_string != "":
					nav_region.set_meta("class", class_string)
				if _add_id_as_metadata and obj_id != 0:
					nav_region.set_meta("id", obj_id)
				if obj.has("properties"):
					handle_properties(nav_region, obj["properties"])
			elif godot_type == _godot_type.OCCLUDER:
				var light_occ = LightOccluder2D.new()
				layer_node.add_child(light_occ)
				light_occ.owner = _base_node
				light_occ.name = obj_name + " (LO)" if obj_name != "" else "Occluder"
				light_occ.position = object_base_coords
				light_occ.rotation_degrees = obj_rot
				light_occ.visible = obj_visible
				var occ_poly = OccluderPolygon2D.new()
				light_occ.occluder = occ_poly
				occ_poly.polygon = polygon_from_array(obj["polygon"])
				if _add_class_as_metadata and class_string != "":
					light_occ.set_meta("class", class_string)
				if _add_id_as_metadata and obj_id != 0:
					light_occ.set_meta("id", obj_id)
				if obj.has("properties"):
					handle_properties(light_occ, obj["properties"])
			elif godot_type == _godot_type.POLYGON:
				var polygon = Polygon2D.new()
				layer_node.add_child(polygon)
				polygon.owner = _base_node
				polygon.name = obj_name if obj_name != "" else "Polygon"
				polygon.position = object_base_coords
				polygon.rotation_degrees = obj_rot
				polygon.visible = obj_visible
				polygon.polygon = polygon_from_array(obj["polygon"])
				if _add_class_as_metadata and class_string != "":
					polygon.set_meta("class", class_string)
				if _add_id_as_metadata and obj_id != 0:
					polygon.set_meta("id", obj_id)
				if obj.has("properties"):
					handle_properties(polygon, obj["properties"])	
		elif obj.has("polyline"):
			if godot_type == _godot_type.LINE:
				var line = Line2D.new()
				layer_node.add_child(line)
				line.owner = _base_node
				line.name = obj_name if obj_name != "" else "Line"
				line.position = object_base_coords
				line.visible = obj_visible
				line.rotation_degrees = obj_rot
				line.width = 1.0
				line.points = polygon_from_array(obj["polyline"])
				if _add_class_as_metadata and class_string != "":
					line.set_meta("class", class_string)
				if _add_id_as_metadata and obj_id != 0:
					line.set_meta("id", obj_id)
				if obj.has("properties"):
					handle_properties(line, obj["properties"])
			elif godot_type == _godot_type.PATH:
				var path = Path2D.new()
				layer_node.add_child(path)
				path.owner = _base_node
				path.name = obj_name if obj_name != "" else "Path"
				path.position = object_base_coords
				path.visible = obj_visible
				path.rotation_degrees = obj_rot
				var curve = Curve2D.new()
				for point in obj["polyline"]:
					curve.add_point(Vector2(point.x, point.y))
				path.curve = curve
				if _add_class_as_metadata and class_string != "":
					path.set_meta("class", class_string)
				if _add_id_as_metadata and obj_id != 0:
					path.set_meta("id", obj_id)
				if obj.has("properties"):
					handle_properties(path, obj["properties"])
			else:
				var co: CollisionObject2D
				if godot_type == _godot_type.AREA:
					co = Area2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (Area)" if obj_name != "" else "Area"
				elif godot_type == _godot_type.ABODY:
					co = AnimatableBody2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (AB)" if obj_name != "" else "AnimatableBody"
				else:
					co = StaticBody2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (SB)" if obj_name != "" else "StaticBody"
				co.owner = _base_node
				co.position = object_base_coords
				co.visible = obj_visible
				var polyline_points: Array = obj["polyline"]
				for i in range(0, polyline_points.size()-1):
					var collision_shape = CollisionShape2D.new()
					co.add_child(collision_shape)
					var segment_shape = SegmentShape2D.new()
					segment_shape.a = transpose_coords(polyline_points[i]["x"], polyline_points[i]["y"], true)
					segment_shape.b = transpose_coords(polyline_points[i+1]["x"], polyline_points[i+1]["y"], true)
					collision_shape.owner = _base_node
					collision_shape.shape = segment_shape
					collision_shape.position = Vector2(obj_width / 2.0, obj_height / 2.0)
					collision_shape.rotation_degrees = obj_rot
					collision_shape.name = "Segment Shape"
				if _add_class_as_metadata and class_string != "":
					co.set_meta("class", class_string)
				if _add_id_as_metadata and obj_id != 0:
					co.set_meta("id", obj_id)
				if obj.has("properties"):
					handle_properties(co, obj["properties"])
		else:
			if godot_type == _godot_type.BODY or godot_type == _godot_type.ABODY or godot_type == _godot_type.AREA:
				var co: CollisionObject2D
				if godot_type == _godot_type.AREA:
					co = Area2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (Area)" if obj_name != "" else "Area"
				elif godot_type == _godot_type.ABODY:
					co = AnimatableBody2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (AB)" if obj_name != "" else "AnimatableBody"
				else:
					co = StaticBody2D.new()
					layer_node.add_child(co)
					co.name = obj_name + " (SB)" if obj_name != "" else "StaticBody"
				co.owner = _base_node
				co.position = object_base_coords
				co.visible = obj_visible

				var collision_shape = CollisionShape2D.new()
				co.add_child(collision_shape)
				collision_shape.owner = _base_node
				var obj_rot_orig = obj_rot
				if obj.has("capsule") or obj.has("ellipse"):
					var capsule_shape = CapsuleShape2D.new()
					if obj_height >= obj_width:
						capsule_shape.height = obj_height
						capsule_shape.radius = obj_width / 2.0
					else:
						capsule_shape.height = obj_width
						capsule_shape.radius = obj_height / 2.0
						obj_rot += 90
					collision_shape.shape = capsule_shape
					collision_shape.name = obj_name if obj_name != "" else "Capsule Shape"
				else: #Rectangle
					var rectangle_shape = RectangleShape2D.new()
					rectangle_shape.size = Vector2(obj_width, obj_height)
					collision_shape.shape = rectangle_shape
					collision_shape.name = obj_name if obj_name != "" else "Rectangle Shape"

				if _map_orientation == "isometric":
					if _iso_rot == 0.0:
						var q = float(_map_tile_height) / float(_map_tile_width)
						q *= q
						var cos_a = sqrt(1 / (q + 1))
						_iso_rot = acos(cos_a) * 180 / PI
						_iso_skew = (90 - 2 * _iso_rot) * PI / 180
						var scale = float(_map_tile_width) / (float(_map_tile_height) * 2 * cos_a)
						_iso_scale = Vector2(scale, scale)

					if obj_height >= obj_width or collision_shape.shape is RectangleShape2D:
						collision_shape.skew = _iso_skew
						obj_rot += _iso_rot
					else:
						collision_shape.skew = -_iso_skew
						obj_rot += -90 - _iso_rot
	
					collision_shape.scale = _iso_scale

				collision_shape.position = transpose_coords(obj_width / 2.0, obj_height / 2.0, true)
				collision_shape.position += get_position_offset(obj_width, obj_height, obj_rot_orig)
				collision_shape.rotation_degrees = obj_rot
				collision_shape.visible = obj_visible
				if _add_class_as_metadata and class_string != "":
					co.set_meta("class", class_string)
				if _add_id_as_metadata and obj_id != 0:
					co.set_meta("id", obj_id)
				if obj.has("properties"):
					handle_properties(co, obj["properties"])
			elif godot_type == _godot_type.NAVIGATION:
				if obj.has("capsule"):
					print_rich("[color="+WARNING_COLOR+"] -- Capsule is unusable for NavigationRegion2D. -> Skipped[/color]")
					CommonUtils.warning_count += 1
				elif obj.has("ellipse"):
					print_rich("[color="+WARNING_COLOR+"] -- Ellipse is unusable for NavigationRegion2D. -> Skipped[/color]")
					CommonUtils.warning_count += 1
				else:
					var nav_region = NavigationRegion2D.new()
					layer_node.add_child(nav_region)
					nav_region.owner = _base_node
					nav_region.name = obj_name + " (NR)" if obj_name != "" else "Navigation"
					nav_region.position = object_base_coords
					nav_region.rotation_degrees = obj_rot
					nav_region.visible = obj_visible
					var nav_poly = NavigationPolygon.new()
					nav_region.navigation_polygon = nav_poly
					var pg = polygon_from_rectangle(obj_width, obj_height)
					nav_poly.add_outline(pg)
					#nav_poly.make_polygons_from_outlines()
					# Replaced in 4.2 deprecated function make_polygons_from_outlines
					nav_poly.vertices = pg
					var polygon = PackedInt32Array()
					for idx in range(nav_poly.vertices.size()):
						polygon.push_back(idx)
					nav_poly.add_polygon(polygon)

					if _add_class_as_metadata and class_string != "":
						nav_region.set_meta("class", class_string)
					if _add_id_as_metadata and obj_id != 0:
						nav_region.set_meta("id", obj_id)		
					if obj.has("properties"):
						handle_properties(nav_region, obj["properties"])
			elif godot_type == _godot_type.OCCLUDER:
				if obj.has("capsule"):
					print_rich("[color="+WARNING_COLOR+"] -- Capsule is unusable for LightOccluder2D. -> Skipped[/color]")
					CommonUtils.warning_count += 1
				elif obj.has("ellipse"):
					print_rich("[color="+WARNING_COLOR+"] -- Ellipse is unusable for LightOccluder2D. -> Skipped[/color]")
					CommonUtils.warning_count += 1
				else:
					var light_occ = LightOccluder2D.new()
					layer_node.add_child(light_occ)
					light_occ.owner = _base_node
					light_occ.name = obj_name + " (LO)" if obj_name != "" else "Occluder"
					light_occ.position = object_base_coords
					light_occ.rotation_degrees = obj_rot
					light_occ.visible = obj_visible
					var occ_poly = OccluderPolygon2D.new()
					light_occ.occluder = occ_poly
					occ_poly.polygon = polygon_from_rectangle(obj_width, obj_height)
					if _add_class_as_metadata and class_string != "":
						light_occ.set_meta("class", class_string)
					if _add_id_as_metadata and obj_id != 0:
						light_occ.set_meta("id", obj_id)
					if obj.has("properties"):
						handle_properties(light_occ, obj["properties"])
			elif godot_type == _godot_type.POLYGON:
				if obj.has("capsule"):
					print_rich("[color="+WARNING_COLOR+"] -- Capsule is unusable for Polygon2D. -> Skipped[/color]")
					CommonUtils.warning_count += 1
				elif obj.has("ellipse"):
					print_rich("[color="+WARNING_COLOR+"] -- Ellipse is unusable for Polygon2D. -> Skipped[/color]")
					CommonUtils.warning_count += 1
				else:
					var polygon = Polygon2D.new()
					layer_node.add_child(polygon)
					polygon.owner = _base_node
					polygon.name = obj_name if obj_name != "" else "Polygon"
					polygon.position = object_base_coords
					polygon.rotation_degrees = obj_rot
					polygon.visible = obj_visible
					polygon.polygon = polygon_from_rectangle(obj_width, obj_height)
					if _add_class_as_metadata and class_string != "":
						polygon.set_meta("class", class_string)
					if _add_id_as_metadata and obj_id != 0:
						polygon.set_meta("id", obj_id)		
					if obj.has("properties"):
						handle_properties(polygon, obj["properties"])	


func add_collision_shapes(parent: CollisionObject2D, object_group: Dictionary, tile_width: float, tile_height: float, flippedH: bool, flippedV: bool, scale: Vector2):
	var objects = object_group["objects"]
	for obj in objects:
		var obj_name = str(obj.get("name", ""))
		if obj.has("point") and obj["point"]:
			print_rich("[color="+WARNING_COLOR+"] -- 'Point' has currently no corresponding collision element in Godot 4. -> Skipped[/color]")
			CommonUtils.warning_count += 1
			break

		var fact = tile_height / _map_tile_height
		var object_base_coords = Vector2(obj["x"], obj["y"]) * scale
		if _current_tileset_orientation == "isometric":
			object_base_coords = transpose_coords(obj["x"], obj["y"], true) * scale
			tile_width = _map_tile_width
			tile_height = _map_tile_height

		if obj.has("polygon"):
			var polygon_points = obj["polygon"] as Array
			var rot = obj.get("rotation", 0.0)			
			var polygon = []
			for pt in polygon_points:
				var p_coord = Vector2(pt["x"], pt["y"]) * scale
				if _current_tileset_orientation == "isometric":
					p_coord = transpose_coords(p_coord.x, p_coord.y, true)
				if flippedH:
					p_coord.x = -p_coord.x
				if flippedV:
					p_coord.y = -p_coord.y
				polygon.append(p_coord)

			var collision_polygon = CollisionPolygon2D.new()
			parent.add_child(collision_polygon)
			collision_polygon.owner = _base_node
			collision_polygon.polygon = polygon
			var pos_x = object_base_coords.x
			var pos_y = object_base_coords.y - tile_height
			if _map_orientation == "isometric" and _current_tileset_orientation == "orthogonal":
				pos_x -= tile_width / 2.0
			if flippedH:
				pos_x = tile_width - pos_x
				if _map_orientation == "isometric":
					pos_x -= tile_width
				rot = -rot
			if flippedV:
				pos_y = -tile_height - pos_y
				if _current_tileset_orientation == "isometric":
					pos_y -= _map_tile_height * fact - tile_height
				rot = -rot
			collision_polygon.rotation_degrees = rot
			collision_polygon.position = Vector2(pos_x, pos_y)
			collision_polygon.name = obj_name if obj_name != "" else "Collision Polygon"
			if get_property(obj, "one_way", "bool") == "true":
				collision_polygon.one_way_collision = true
			var coll_margin = get_property(obj, "one_way_margin", "int")
			if coll_margin == "":
				coll_margin = get_property(obj, "one_way_margin", "float")
			if coll_margin != "":
				collision_polygon.one_way_collision_margin = coll_margin
		else:
			# Ellipse or rectangle
			var collision_shape = CollisionShape2D.new()
			parent.add_child(collision_shape)
			collision_shape.owner = _base_node
			var x = obj["x"] * scale.x
			var y = obj["y"] * scale.y
			var w = obj["width"] * scale.x
			var h = obj["height"] * scale.y
			var rot = obj.get("rotation", 0.0)
			var sin_a = sin(rot * PI / 180.0)
			var cos_a = cos(rot * PI / 180.0)
			var pos_x = x + w / 2.0 * cos_a - h / 2.0 * sin_a
			var pos_y = -tile_height + y + h / 2.0 * cos_a + w / 2.0 * sin_a
			if _current_tileset_orientation == "isometric":
				var trans_pos = transpose_coords(pos_x, pos_y, true)
				pos_x = trans_pos.x
				pos_y = trans_pos.y
				pos_x -= tile_width / 2.0 - h * fact / 4.0 * sin_a
				pos_y -= tile_height / 2.0
			elif _map_orientation == "isometric":
				pos_x -= tile_width / 2.0
			if flippedH:
				pos_x = tile_width - pos_x 
				if _map_orientation == "isometric":
					pos_x -= tile_width
				rot = -rot
			if flippedV:
				pos_y = -tile_height - pos_y
				if _current_tileset_orientation == "isometric":
					pos_y -= _map_tile_height * fact - tile_height
				rot = -rot
			collision_shape.position = Vector2(pos_x, pos_y)
			collision_shape.scale = scale
			var shape
			if (obj.has("capsule") and obj["capsule"]) or (obj.has("ellipse") and obj["ellipse"]):
				shape = CapsuleShape2D.new()
				if h >= w:
					shape.height = h / scale.y
					shape.radius = w / 2.0 / scale.x
				else:
					shape.height = w / scale.y
					shape.radius = h / 2.0 / scale.x
					rot += 90
				collision_shape.name = obj_name if obj_name != "" else "Capsule Shape"
			else:
				shape = RectangleShape2D.new()
				shape.size = Vector2(w, h) / scale
				collision_shape.name = obj_name if obj_name != "" else "Rectangle Shape"

			if _current_tileset_orientation == "isometric":
				if _iso_rot == 0.0:
					var q = float(_map_tile_height) / float(_map_tile_width)
					q *= q
					var cos_b = sqrt(1 / (q + 1))
					_iso_rot = acos(cos_b) * 180 / PI
					_iso_skew = (90 - 2 * _iso_rot) * PI / 180
					var scale_b = float(_map_tile_width) / (float(_map_tile_height) * 2 * cos_b)
					_iso_scale = Vector2(scale_b, scale_b)

				var effective_rot = _iso_rot
				var effective_skew = _iso_skew

				if w > h and shape is CapsuleShape2D:
					effective_rot = -_iso_rot
					effective_skew = -_iso_skew
					rot -= 90

				if flippedH:
					effective_rot = -effective_rot
					effective_skew = -effective_skew
				if flippedV:
					effective_rot = -effective_rot
					effective_skew = -effective_skew
	
				collision_shape.skew = effective_skew
				collision_shape.scale = _iso_scale
				rot += effective_rot

			collision_shape.shape = shape
			collision_shape.rotation_degrees = rot
			if get_property(obj, "one_way", "bool") == "true":
				collision_shape.one_way_collision = true
			var coll_margin = get_property(obj, "one_way_margin", "int")
			if coll_margin == "":
				coll_margin = get_property(obj, "one_way_margin", "float")
			if coll_margin != "":
				collision_shape.one_way_collision_margin = coll_margin


static func get_property(obj: Dictionary, property_name: String, property_type: String) -> String:
	var ret = ""
	if not obj.has("properties"): return ret
	for property in obj["properties"]:
		var name = property.get("name", "")
		var type = property.get("type", "string")
		var val = str(property.get("value", ""))
		if name.to_lower() == property_name and type == property_type:
			return val
	return ret


func polygon_from_array(poly_array: Array):
	var polygon = []
	for pt in poly_array:
		var p_coord = transpose_coords(pt["x"], pt["y"], true)
		polygon.append(p_coord)
	return polygon


func polygon_from_rectangle(width: float, height: float):
	var polygon = [Vector2(), Vector2(), Vector2(), Vector2()]
	polygon[0] = Vector2.ZERO
	polygon[1].y = polygon[0].y + height
	polygon[1].x = polygon[0].x
	polygon[2].y = polygon[1].y
	polygon[2].x = polygon[0].x + width
	polygon[3].y = polygon[0].y
	polygon[3].x = polygon[2].x
	polygon[1] = transpose_coords(polygon[1].x, polygon[1].y, true)
	polygon[2] = transpose_coords(polygon[2].x, polygon[2].y, true)
	polygon[3] = transpose_coords(polygon[3].x, polygon[3].y, true)
	return polygon


func get_rotated_polygon(polygon: Array, rotation: float) -> Array:
	var ret = []
	var rot_rad = rotation * PI / 180.0
	for vertex in polygon:
		ret.append(vertex.rotated(rot_rad))
	return ret


func transpose_coords(x: float, y: float, no_offset_x: bool = false):
	if _map_orientation == "isometric":
		var trans_x = (x - y) * _map_tile_width / _map_tile_height / 2.0
		if not no_offset_x:
			trans_x += _map_height * _map_tile_width / 2.0
		var trans_y = (x + y) * 0.5
		return Vector2(trans_x, trans_y)

	return Vector2(x, y)


func get_first_gid_index(gid: int):
	var index = 0
	var gid_index = 0
	for first_gid in _first_gids:
		if gid >= first_gid:
			gid_index = index
		index += 1
	return gid_index


func get_atlas_source_index(gid: int):
	var idx = -1
	if _atlas_sources == null:
		return -1
	for src in _atlas_sources:
		idx += 1
		var first_gid: int = src["firstGid"]
		var effective_gid = gid - first_gid + 1
		var assigned_id: int = src["assignedId"]
		if assigned_id < 0:
			var limit: int = src["numTiles"]
			if effective_gid <= limit and first_gid == _first_gids[get_first_gid_index(gid)]:
				return idx
		elif effective_gid == (assigned_id + 1):
			return idx
		
	return -1
	
	
func get_matching_source_id(gid: int):
	var idx = get_atlas_source_index(gid)
	if idx < 0:
		return -1
	return _atlas_sources[idx]["sourceId"]
	
	
func get_tile_offset(gid: int):
	var idx = get_atlas_source_index(gid)
	if idx < 0:
		return Vector2i.ZERO
	return _atlas_sources[idx]["tileOffset"]
		
	
func get_tileset_orientation(gid: int):
	var idx = get_atlas_source_index(gid)
	if idx < 0:
		return _map_orientation
	return _atlas_sources[idx]["tilesetOrientation"]
		
	
func get_tileset_alignment(gid: int):
	var idx = get_atlas_source_index(gid)
	if idx < 0:
		return DEFAULT_ALIGNMENT
	return _atlas_sources[idx]["objectAlignment"]	


func get_tileset_shader_material(gid: int):
	var idx = get_atlas_source_index(gid)
	if idx < 0:
		return null
	return _atlas_sources[idx]["shaderMaterial"]	


func is_partitioned_tileset(source_id: int) -> bool:
	for src in _atlas_sources:
		if src["sourceId"] == source_id:
			return (src["assignedId"] < 0)
	return false


func get_num_tiles_for_source_id(source_id: int):
	for src in _atlas_sources:
		if src["sourceId"] == source_id:
			return src["numTiles"]
	return -1


func get_object_group(index: int):
	var ret = null
	if _object_groups != null:
		ret = _object_groups.get(index, null)
	return ret


func get_object(index: int):
	if not _base_dictionary.has("layers"): return null
	for layer in _base_dictionary["layers"]:
		if not layer.has("objects"): continue
		for obj in layer["objects"]:
			if index == obj.get("id", 0):
				return obj
	return null


func get_object_polygon(obj_id: int):
	var obj_ = get_object(obj_id)
	if obj_ == null:
		return null
	var obj = obj_ as Dictionary
	var obj_x = obj.get("x", 0.0)
	var obj_y = obj.get("y", 0.0)
	var obj_rot = obj.get("rotation", 0.0)
	var ret = null
	if obj.has("polygon"):
		var pg = get_rotated_polygon(polygon_from_array(obj["polygon"]), obj_rot)
		var i = 0
		for vertex in pg:
			pg[i] += Vector2(obj_x, obj_y)
			i += 1
		ret = PackedVector2Array(pg)
	elif obj.has("polyline"):
		var pl = get_rotated_polygon(polygon_from_array(obj["polyline"]), obj_rot)
		var i = 0
		for vertex in pl:
			pl[i] += Vector2(obj_x, obj_y)
			i += 1
		ret = PackedVector2Array(pl)
	elif obj.has("point"):
		ret = Vector2(obj_x, obj_y)
	elif not obj.has("ellipse") and not obj.has("capsule") and not obj.has("gid"):
		# Should be a rectangle
		var obj_width = obj.get("width", 0.0)
		var obj_height = obj.get("height", 0.0)
		var rect = []
		rect.append(Vector2(0.0, 0.0))
		rect.append(Vector2(obj_width, 0.0))
		rect.append(Vector2(obj_width, obj_height))
		rect.append(Vector2(0.0, obj_height))
		var rot_rect = get_rotated_polygon(rect, obj_rot)
		var i = 0
		for vertex in rot_rect:
			rot_rect[i] += Vector2(obj_x, obj_y)
			i += 1
		ret = PackedVector2Array(rot_rect)
	return ret


func handle_list_property(current_array: Array, current_value: Array):
	for item in current_value:
		var item_type: String = item.get("type", "string")
		var item_val = item["value"]
		if item_type == "list":
			var list_val = []
			current_array.append(list_val)
			handle_list_property(list_val, item_val)
		elif item_type == "object":
			var obj = get_object_polygon(item_val)
			if obj != null:
				current_array.append(obj)
			else:
				current_array.append(CommonUtils.get_right_typed_value(item_type, str(item_val)))
		else:
			current_array.append(CommonUtils.get_right_typed_value(item_type, str(item_val)))


func handle_properties(target_node: Node, properties: Array):
	var has_children = false
	if target_node is StaticBody2D or target_node is Area2D or target_node is CharacterBody2D or target_node is RigidBody2D or target_node is AnimatableBody2D:
		has_children = target_node.get_child_count() > 0 
	for property in properties:
		var name: String = property.get("name", "")
		var type: String = property.get("type", "string")
		var list_val = ""
		var val: String = ""
		if type == "list":
			list_val = []
			handle_list_property(list_val, property["value"])
		else:
			val = str(property.get("value", ""))
		if name == "" or name.to_lower() == GODOT_NODE_TYPE_PROPERTY or name.to_lower() == "res_path": continue
		if name.begins_with("__") and has_children:
			var child_prop_dict = {}
			child_prop_dict["name"] = name.substr(2)
			child_prop_dict["type"] = type
			child_prop_dict["value"] = val
			var child_props = []
			child_props.append(child_prop_dict)
			for child in target_node.get_children():
				handle_properties(child, child_props)
		
		# Node properties
		# v1.5.4: godot_group property
		if name.to_lower() == GODOT_GROUP_PROPERTY and type == "string":
			for group in val.split(",", false):
				target_node.add_to_group(group.strip_edges(), true)

		# v1.6.6: script resource and godot_script property
		elif name.to_lower() == GODOT_SCRIPT_PROPERTY and (type == "file" or type == "string"):
			var path = val
			if type == "file":
				path = CommonUtils.cleanup_path(_base_path.replace("res://", "") + "/" + val)
			target_node.set_script(load(path))

		# CanvasItem properties
		elif name.to_lower() == "modulate" and type == "string":
			target_node.modulate = Color(val)
		elif name.to_lower() == "self_modulate" and type == "string":
			target_node.self_modulate = Color(val)
		elif name.to_lower() == "show_behind_parent" and type == "bool":
			target_node.show_behind_parent = val.to_lower() == "true"
		elif name.to_lower() == "top_level" and type == "bool":
			target_node.top_level = val.to_lower() == "true"
		elif name.to_lower() == "clip_children" and type == "int":
			if int(val) < CanvasItem.CLIP_CHILDREN_MAX:
				target_node.clip_children = int(val)
		elif name.to_lower() == "light_mask" and type == "string":
			target_node.light_mask = CommonUtils.get_bitmask_integer_from_string(val, 20)
		elif name.to_lower() == "visibility_layer" and type == "string":
			target_node.visibility_layer = CommonUtils.get_bitmask_integer_from_string(val, 20)
		elif name.to_lower() == "z_index" and type == "int":
			target_node.z_index = int(val)
			# Preserve authored values for post-processors which rebuild nodes
			# or assign a default layer order (as the Godot 3 importer did).
			target_node.set_meta("z_index", int(val))
		elif name.to_lower() == "z_as_relative" and type == "bool":
			target_node.z_as_relative = val.to_lower() == "true"
			target_node.set_meta("z_as_relative", val.to_lower() == "true")
		elif name.to_lower() == "y_sort_enabled" and type == "bool":
			target_node.y_sort_enabled = val.to_lower() == "true"
			target_node.set_meta("y_sort_enabled", val.to_lower() == "true")
		elif name.to_lower() == "texture_filter" and type == "int":
			if int(val) < CanvasItem.TEXTURE_FILTER_MAX:
				target_node.texture_filter = int(val)
		elif name.to_lower() == "texture_repeat" and type == "int":
			if int(val) < CanvasItem.TEXTURE_REPEAT_MAX:
				target_node.texture_repeat = int(val)
		elif name.to_lower() == "material" and type == "file":
			target_node.material = DataLoader.load_resource_from_file(val, _base_path)
		elif name.to_lower() == "use_parent_material" and type == "bool":
			target_node.use_parent_material = val.to_lower() == "true"
	
		# TileMapLayer properties
		elif name.to_lower() == "tile_set" and type == "file" and target_node is TileMapLayer:
			target_node.tile_set = DataLoader.load_resource_from_file(val, _base_path)

		# Experimental only! Not sure if properly functioning
		elif name.to_lower() == "tileset_resource_path" and type == "string" and target_node is TileMapLayer:
			var tileset = target_node.tile_set
			tileset.resource_path = val

		elif name.to_lower() == "y_sort_origin" and type == "int" and target_node is TileMapLayer:
			target_node.y_sort_origin = int(val)
		elif name.to_lower() == "x_draw_order_reversed" and type == "bool" and target_node is TileMapLayer:
			target_node.x_draw_order_reversed = val.to_lower() == "true"
		elif name.to_lower() == "rendering_quadrant_size" and type == "int" and target_node is TileMapLayer:
			target_node.rendering_quadrant_size = int(val)
		elif name.to_lower() == "collision_enabled" and type == "bool" and target_node is TileMapLayer:
			target_node.collision_enabled = val.to_lower() == "true"
		elif name.to_lower() == "use_kinematic_bodies" and type == "bool" and target_node is TileMapLayer:
			target_node.use_kinematic_bodies = val.to_lower() == "true"
		elif name.to_lower() == "collision_visibility_mode" and type == "int" and target_node is TileMapLayer:
			if int(val) < 3:
				target_node.collision_visibility_mode = int(val)
		elif name.to_lower() == "navigation_enabled" and type == "bool" and target_node is TileMapLayer:
			target_node.navigation_enabled = val.to_lower() == "true"
		elif name.to_lower() == "navigation_visibility_mode" and type == "int" and target_node is TileMapLayer:
			if int(val) < 3:
				target_node.navigation_visibility_mode = int(val)

		# Parallax2D properties
		elif name.to_lower() == "scroll_scale_x" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.scroll_scale = Vector2(float(val), target_node.scroll_scale.y)
		elif name.to_lower() == "scroll_scale_y" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.scroll_scale = Vector2(target_node.scroll_scale.x, float(val))
		elif name.to_lower() == "scroll_offset_x" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.scroll_offset = Vector2(float(val), target_node.scroll_offset.y)
		elif name.to_lower() == "scroll_offset_y" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.scroll_offset = Vector2(target_node.scroll_offset.x, float(val))
		elif name.to_lower() == "repeat_size_x" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.repeat_size = Vector2(float(val), target_node.repeat_size.y)
		elif name.to_lower() == "repeat_size_y" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.repeat_size = Vector2(target_node.repeat_size.x, float(val))
		elif name.to_lower() == "autoscroll_x" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.autoscroll = Vector2(float(val), target_node.autoscroll.y)
		elif name.to_lower() == "autoscroll_y" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.autoscroll = Vector2(target_node.autoscroll.x, float(val))
		elif name.to_lower() == "repeat_times" and type == "int" and target_node is Parallax2D:
			target_node.repeat_times = int(val)
		elif name.to_lower() == "limit_begin_x" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.limit_begin = Vector2(float(val), target_node.limit_begin.y)
		elif name.to_lower() == "limit_begin_y" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.limit_begin = Vector2(target_node.limit_begin.x, float(val))
		elif name.to_lower() == "limit_end_x" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.limit_end = Vector2(float(val), target_node.limit_end.y)
		elif name.to_lower() == "limit_end_y" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.limit_end = Vector2(target_node.limit_end.x, float(val))
		elif name.to_lower() == "follow_viewport" and type == "bool" and target_node is Parallax2D:
			target_node.follow_viewport = val.to_lower() == "true"
		elif name.to_lower() == "ignore_camera_scroll" and type == "bool" and target_node is Parallax2D:
			target_node.ignore_camera_scroll = val.to_lower() == "true"
		elif name.to_lower() == "screen_offset_x" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.screen_offset = Vector2(float(val), target_node.screen_offset.y)
		elif name.to_lower() == "screen_offset_y" and (type == "float" or type == "int") and target_node is Parallax2D:
			target_node.screen_offset = Vector2(target_node.screen_offset.x, float(val))

		# CollisionObject2D properties
		elif name.to_lower() == "disable_mode" and type == "int" and target_node is CollisionObject2D:
			if int(val) < 3:
				target_node.disable_mode = int(val)
		elif name.to_lower() == "collision_layer" and type == "string" and target_node is CollisionObject2D:
			target_node.collision_layer = CommonUtils.get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "collision_mask" and type == "string" and target_node is CollisionObject2D:
			target_node.collision_mask = CommonUtils.get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "collision_priority" and  (type == "float" or type == "int") and target_node is CollisionObject2D:
			target_node.collision_priority = float(val)
		elif name.to_lower() == "input_pickable" and type == "bool" and target_node is CollisionObject2D:
			target_node.input_pickable = val.to_lower() == "true"

		# CollisionPolygon2D properties
		elif name.to_lower() == "build_mode" and type == "int" and has_children and int(val) < 2:
			for child in target_node.get_children():
				if child is CollisionPolygon2D:
					child.build_mode = int(val)

		# CollisionPolygon2D & CollisionShape2D properties
		elif name.to_lower() == "disabled" and type == "bool" and has_children:
			for child in target_node.get_children():
				child.disabled = val.to_lower() == "true"
		elif name.to_lower() == "one_way_collision" and type == "bool" and has_children:
			for child in target_node.get_children():
				child.one_way_collision = val.to_lower() == "true"
		elif name.to_lower() == "one_way_collision_margin" and (type == "float" or type == "int") and has_children:
			for child in target_node.get_children():
				child.one_way_collision_margin = float(val)

		# CollisionShape2D properties
		elif name.to_lower() == "debug_color" and type == "string" and has_children:
			for child in target_node.get_children():
				if child is CollisionShape2D:
					child.debug_color = Color(val)

		# Area2D properties
		elif name.to_lower() == "monitoring" and type == "bool" and target_node is Area2D:
			target_node.monitoring = val.to_lower() == "true"
		elif name.to_lower() == "monitorable" and type == "bool" and target_node is Area2D:
			target_node.monitorable = val.to_lower() == "true"
		elif name.to_lower() == "priority" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.priority = float(val)
		elif name.to_lower() == "gravity_space_override" and type == "int" and target_node is Area2D:
			if int(val) < 5:
				target_node.gravity_space_override = int(val)
		elif name.to_lower() == "gravity_point" and type == "bool" and target_node is Area2D:
			target_node.gravity_point = val.to_lower() == "true"
		elif name.to_lower() == "gravitiy_point_center_x" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravity_point_center = Vector2(float(val), target_node.gravity_point_center.y)
		elif name.to_lower() == "gravitiy_point_center_y" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravity_point_center = Vector2(target_node.gravity_point_center.x, float(val))
		elif name.to_lower() == "gravity_point_unit_distance" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravitiy_point_unit_distance = float(val)
		elif name.to_lower() == "gravitiy_direction_x" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravity_direction = Vector2(float(val), target_node.gravity_direction.y)
		elif name.to_lower() == "gravitiy_direction_y" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravity_direction = Vector2(target_node.gravity_direction.x, float(val))
		elif name.to_lower() == "gravity" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.gravitiy = float(val)
		elif name.to_lower() == "linear_damp_space_override" and type == "int" and target_node is Area2D:
			if int(val) < 5:
				target_node.linear_damp_space_override = int(val)
		elif name.to_lower() == "linear_damp" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.linear_damp = float(val)
		elif name.to_lower() == "angular_damp_space_override" and type == "int" and target_node is Area2D:
			if int(val) < 5:
				target_node.angular_damp_space_override = int(val)
		elif name.to_lower() == "angular_damp" and (type == "float" or type == "int") and target_node is Area2D:
			target_node.angular_damp = float(val)
			
		# StaticBody2D properties
		elif name.to_lower() == "physics_material_override" and type == "file" and target_node is StaticBody2D:
			target_node.physics_material_override = DataLoader.load_resource_from_file(val, _base_path)
		elif name.to_lower() == "constant_linear_velocity_x" and (type == "float" or type == "int") and target_node is StaticBody2D:
			target_node.constant_linear_velocity = Vector2(float(val), target_node.constant_linear_velocity.y)
		elif name.to_lower() == "constant_linear_velocity_y" and (type == "float" or type == "int") and target_node is StaticBody2D:
			target_node.constant_linear_velocity = Vector2(target_node.constant_linear_velocity.x, float(val))
		elif name.to_lower() == "constant_angular_velocity" and (type == "float" or type == "int") and target_node is StaticBody2D:
			target_node.constant_angular_velocity = float(val)

		# AnimatableBody2D properties
		elif name.to_lower() == "sync_to_physics" and type == "bool" and target_node is AnimatableBody2D:
			target_node.sync_to_physics = val.to_lower() == "true"

		# CharacterBody2D properties
		elif name.to_lower() == "motion_mode" and type == "int" and target_node is CharacterBody2D:
			if int(val) < 2:
				target_node.motion_mode = int(val)
		elif name.to_lower() == "up_direction_x" and (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.up_direction = Vector2(float(val), target_node.up_direction.y)
		elif name.to_lower() == "up_direction_y" and (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.up_direction = Vector2(target_node.up_direction.x, float(val))
		elif name.to_lower() == "slide_on_ceiling" and type == "bool" and target_node is CharacterBody2D:
			target_node.slide_on_ceiling = val.to_lower() == "true"
		elif name.to_lower() == "wall_min_slide_angle" and (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.wall_min_slide_angle = float(val)
		elif name.to_lower() == "floor_stop_on_slope" and type == "bool" and target_node is CharacterBody2D:
			target_node.floor_stop_on_slope = val.to_lower() == "true"
		elif name.to_lower() == "floor_constant_speed" and type == "bool" and target_node is CharacterBody2D:
			target_node.floor_constant_speed = val.to_lower() == "true"
		elif name.to_lower() == "floor_block_on_wall" and type == "bool" and target_node is CharacterBody2D:
			target_node.floor_block_on_wall = val.to_lower() == "true"
		elif name.to_lower() == "floor_max_angle" and (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.floor_max_angle = float(val)
		elif name.to_lower() == "floor_snap_length" and (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.floor_snap_length = float(val)
		elif name.to_lower() == "platform_on_leave" and type == "int" and target_node is CharacterBody2D:
			if int(val) < 3:
				target_node.platform_on_leave = int(val)
		elif name.to_lower() == "platform_floor_layers" and type == "string" and target_node is CharacterBody2D:
			target_node.platform_floor_layers = CommonUtils.get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "platform_wall_layers" and type == "string" and target_node is CharacterBody2D:
			target_node.platform_wall_layers = CommonUtils.get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "safe_margin" and  (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.safe_margin = float(val)
		elif name.to_lower() == "collision_layer" and type == "string" and target_node is CharacterBody2D:
			target_node.collision_layer = CommonUtils.get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "collision_mask" and type == "string" and target_node is CharacterBody2D:
			target_node.collision_mask = CommonUtils.get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "collision_priority" and  (type == "float" or type == "int") and target_node is CharacterBody2D:
			target_node.collision_priority = float(val)

		# RigidBody2D properties
		elif name.to_lower() == "mass" and  (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.mass = float(val)
		elif name.to_lower() == "inertia" and  (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.inertia = float(val)
		elif name.to_lower() == "center_of_mass_mode" and type == "int" and target_node is RigidBody2D:
			if int(val) < 2:
				target_node.center_of_mass_mode = int(val)
		elif name.to_lower() == "physics_material_override" and type == "file" and target_node is RigidBody2D:
			target_node.physics_material_override = DataLoader.load_resource_from_file(val, _base_path)
		elif name.to_lower() == "gravity_scale" and  (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.gravity_scale = float(val)
		elif name.to_lower() == "custom_integrator" and type == "bool" and target_node is RigidBody2D:
			target_node.custom_integrator = val.to_lower() == "true"
		elif name.to_lower() == "continuous_cd" and type == "int" and target_node is RigidBody2D:
			if int(val) < 3:
				target_node.continuous_cd = int(val)
		elif name.to_lower() == "max_contacts_reported" and type == "int" and target_node is RigidBody2D:
			target_node.max_contacts_reported = int(val)
		elif name.to_lower() == "contact_monitor" and type == "bool" and target_node is RigidBody2D:
			target_node.contact_monitor = val.to_lower() == "true"
		elif name.to_lower() == "sleeping" and type == "bool" and target_node is RigidBody2D:
			target_node.sleeping = val.to_lower() == "true"
		elif name.to_lower() == "can_sleep" and type == "bool" and target_node is RigidBody2D:
			target_node.can_sleep = val.to_lower() == "true"
		elif name.to_lower() == "lock_rotation" and type == "bool" and target_node is RigidBody2D:
			target_node.lock_rotation = val.to_lower() == "true"
		elif name.to_lower() == "freeze" and type == "bool" and target_node is RigidBody2D:
			target_node.freeze = val.to_lower() == "true"
		elif name.to_lower() == "freeze_mode" and type == "int" and target_node is RigidBody2D:
			if int(val) < 2:
				target_node.freeze_mode = int(val)
		elif name.to_lower() == "linear_velocity_x" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.linear_velocity = Vector2(float(val), target_node.linear_velocity.y)
		elif name.to_lower() == "linear_velocity_y" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.linear_velocity = Vector2(target_node.linear_velocity.x, float(val))
		elif name.to_lower() == "linear_damp_mode" and type == "int" and target_node is RigidBody2D:
			if int(val) < 2:
				target_node.linear_damp_mode = int(val)
		elif name.to_lower() == "linear_damp" and  (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.linear_damp = float(val)
		elif name.to_lower() == "angular_velocity" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.angular_velocity = float(val)
		elif name.to_lower() == "angular_damp_mode" and type == "int" and target_node is RigidBody2D:
			if int(val) < 2:
				target_node.angular_damp_mode = int(val)
		elif name.to_lower() == "angular_damp" and  (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.angular_damp = float(val)
		elif name.to_lower() == "constant_force_x" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.constant_force = Vector2(float(val), target_node.constant_force.y)
		elif name.to_lower() == "constant_force_y" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.constant_force = Vector2(target_node.constant_force.x, float(val))
		elif name.to_lower() == "constant_torque" and (type == "float" or type == "int") and target_node is RigidBody2D:
			target_node.constant_torque = float(val)
				
		# NavigationRegion2D properties
		elif name.to_lower() == "navigation_polygon" and type == "file" and target_node is NavigationRegion2D:
			target_node.navigation_polygon = DataLoader.load_resource_from_file(val, _base_path)
		elif name.to_lower() == "enabled" and type == "bool" and target_node is NavigationRegion2D:
			target_node.enabled = val.to_lower() == "true"
		elif name.to_lower() == "navigation_layers" and type == "string" and target_node is NavigationRegion2D:
			target_node.navigation_layers = CommonUtils.get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "use_edge_connection" and type == "bool" and target_node is NavigationRegion2D:
			target_node.use_edge_connection = val.to_lower() == "true"
		elif name.to_lower() == "enter_cost" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			target_node.enter_cost = float(val)
		elif name.to_lower() == "travel_cost" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			target_node.travel_cost = float(val)

		# NavigationPolygon properties
		elif name.to_lower() == "parsed_geometry_type" and type == "int" and target_node is NavigationRegion2D:
			if int(val) < 3:
				var nav_poly = target_node.navigation_polygon
				nav_poly.parsed_geometry_type = int(val)
		elif name.to_lower() == "parsed_collision_mask" and type == "string" and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			nav_poly.parsed_collision_mask = CommonUtils.get_bitmask_integer_from_string(val, 32)
		elif name.to_lower() == "source_geometry_mode" and type == "int" and target_node is NavigationRegion2D:
			if int(val) < 3:
				var nav_poly = target_node.navigation_polygon
				nav_poly.source_geometry_mode = int(val)
		elif name.to_lower() == "source_geometry_group_name" and type == "string" and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			nav_poly.source_geometry_group_name = val
		elif name.to_lower() == "cell_size" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			nav_poly.cell_size = float(val)
		elif name.to_lower() == "border_size" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			nav_poly.border_size = float(val)
		elif name.to_lower() == "agent_radius" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			nav_poly.agent_radius = float(val)
		elif name.to_lower() == "baking_rect_x" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			var baking_rect = nav_poly.baking_rect
			var br_pos = baking_rect.position
			br_pos.x = float(val)
			baking_rect.position = br_pos
			nav_poly.baking_rect = baking_rect
		elif name.to_lower() == "baking_rect_y" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			var baking_rect = nav_poly.baking_rect
			var br_pos = baking_rect.position
			br_pos.y = float(val)
			baking_rect.position = br_pos
			nav_poly.baking_rect = baking_rect
		elif name.to_lower() == "baking_rect_w" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			var baking_rect = nav_poly.baking_rect
			var br_size = baking_rect.size
			br_size.x = float(val)
			baking_rect.size = br_size
			nav_poly.baking_rect = baking_rect
		elif name.to_lower() == "baking_rect_h" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			var baking_rect = nav_poly.baking_rect
			var br_size = baking_rect.size
			br_size.y = float(val)
			baking_rect.size = br_size
			nav_poly.baking_rect = baking_rect
		elif name.to_lower() == "baking_rect_offset_x" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			var baking_rect_offset = nav_poly.baking_rect_offset
			baking_rect_offset.x = float(val)
			nav_poly.baking_rect_offset = baking_rect_offset
		elif name.to_lower() == "baking_rect_offset_y" and (type == "float" or type == "int") and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			var baking_rect_offset = nav_poly.baking_rect_offset
			baking_rect_offset.y = float(val)
			nav_poly.baking_rect_offset = baking_rect_offset
		elif name.to_lower() == "resource_local_to_scene" and type == "bool" and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			nav_poly.resource_local_to_scene = val.to_lower() == "true"
		elif name.to_lower() == "resource_name" and type == "string" and target_node is NavigationRegion2D:
			var nav_poly = target_node.navigation_polygon
			nav_poly.resource_name = val

		# LightOccluder2D properties
		elif name.to_lower() == "sdf_collision" and type == "bool" and target_node is LightOccluder2D:
			target_node.sdf_collision = val.to_lower() == "true"
		elif name.to_lower() == "occluder_light_mask" and type == "string" and target_node is LightOccluder2D:
			target_node.occluder_light_mask = CommonUtils.get_bitmask_integer_from_string(val, 20)

		# Polygon2D properties
		elif name.to_lower() == "color" and type == "string" and target_node is Polygon2D:
			target_node.color = Color(val)

		# Line2D properties
		elif name.to_lower() == "width" and (type == "float" or type == "int") and target_node is Line2D:
			target_node.width = float(val)
		elif name.to_lower() == "default_color" and type == "string" and target_node is Line2D:
			target_node.default_color = Color(val)

		# Marker2D properties
		elif name.to_lower() == "gizmo_extents" and (type == "float" or type == "int") and target_node is Marker2D:
			target_node.gizmo_extents = float(val)

		# Other properties are added as Metadata
		else:
			if type == "object":
				var obj = get_object_polygon(int(val))
				if obj != null:
					target_node.set_meta(name, obj)
				else:
					target_node.set_meta(name, CommonUtils.get_right_typed_value(type, val))
			elif type == "list":
				target_node.set_meta(name, list_val)
			else:
				target_node.set_meta(name, CommonUtils.get_right_typed_value(type, val))
