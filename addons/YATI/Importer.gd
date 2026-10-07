# MIT License
#
# Copyright (c) 2023-2025 Roland Helmerichs
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
extends EditorImportPlugin

func _get_importer_name() -> String:
	return "YATI"

func _get_visible_name() -> String:
	return "Import from Tiled"

func _get_recognized_extensions() -> PackedStringArray:
	return PackedStringArray(["tmx", "tmj"])

func _get_resource_type() -> String:
	return "PackedScene"

func _get_save_extension() -> String:
	return "tscn"
	
func _get_priority() -> float:
	return 0.1
	
func _get_preset_count() -> int:
	return 0

func _get_preset_name(preset_index: int) -> String:
	return ""

func _get_import_options(path: String, preset_index: int) -> Array:
	return [
		{ "name": "use_default_filter", "default_value": false },
		{ "name": "add_class_as_metadata", "default_value": false },
		{ "name": "add_id_as_metadata", "default_value": false },
		{ "name": "no_alternative_tiles", "default_value": false },
		{ "name": "map_wangset_to_terrain", "default_value": false },
		{ "name": "custom_data_prefix", "default_value": "data_" },
		{ "name": "tiled_project_file", "default_value": "", "property_hint": PROPERTY_HINT_FILE, "hint_string": "*.tiled-project;Project File" },
		{ "name": "post_processor", "default_value": "", "property_hint": PROPERTY_HINT_FILE, "hint_string": "*.gd;GDScript" },
		{ "name": "save_tileset_to", "default_value": "", "property_hint": PROPERTY_HINT_SAVE_FILE, "hint_string": "*.tres;Resource File" }
	]

func _get_import_order() -> int:
	return 99

func _get_option_visibility(path: String, option_name: StringName, options: Dictionary) -> bool:
	return true

func _import(source_file: String, save_path: String, options: Dictionary, platform_variants: Array, gen_files: Array):
	print("Import file '" + source_file + "'")
	if !FileAccess.file_exists(source_file):
		printerr("Import file '" + source_file + "' not found!")
		return ERR_FILE_NOT_FOUND

	CommonUtils.error_count = 0
	CommonUtils.warning_count = 0

	var ct: CustomTypes = null
	var tilemapCreator = preload("TilemapCreator.gd").new()
	if options["use_default_filter"] == true:
		tilemapCreator.set_use_default_filter(true)
	if options["add_class_as_metadata"] == true:
		tilemapCreator.set_add_class_as_metadata(true)
	if options["add_id_as_metadata"] == true:
		tilemapCreator.set_add_id_as_metadata(true)
	if options["no_alternative_tiles"] == true:
		tilemapCreator.set_no_alternative_tiles(true)
	if options["map_wangset_to_terrain"] == true:
		tilemapCreator.set_map_wangset_to_terrain(true)
	if options["custom_data_prefix"] != "":
		tilemapCreator.set_custom_data_prefix(options["custom_data_prefix"])
	if options.has("tiled_project_file") and options["tiled_project_file"] != "":
		ct = CustomTypes.new()
		ct.load_custom_types(options["tiled_project_file"])
		tilemapCreator.set_custom_types(ct)
	if options.has("save_tileset_to") and options["save_tileset_to"] != "":
		tilemapCreator.set_save_tileset_to(options["save_tileset_to"])

	var node2D = tilemapCreator.create(source_file)
	if node2D == null:
		return FAILED

	var errors = CommonUtils.error_count
	var warnings = CommonUtils.warning_count

	var post_proc_error = false
	if options.has("post_processor") and options["post_processor"] != "":
		var post_proc = preload("PostProcessing.gd").new()
		node2D = post_proc.call_post_process(node2D, options["post_processor"])
		post_proc_error = post_proc.get_error() != OK

	var packed_scene = PackedScene.new()
	packed_scene.pack(node2D)
	# return ResourceSaver.save(packed_scene, source_file.get_basename() + "." + _get_save_extension())
	var ret = ResourceSaver.save(packed_scene, save_path + "." + _get_save_extension())
	# v1.5.3: Copying no longer necessary, leave that to Godot's "Please confirm..." dialog box
	#if ret == OK:
	#	var dir = DirAccess.open(source_file.get_basename().get_base_dir())
	#	ret = dir.copy(save_path + "." + _get_save_extension(), source_file.get_basename() + "." + _get_save_extension())
	if ret == OK:
		var final_message_string = "Import succeeded."
		if post_proc_error:
			final_message_string = "Import finished."
		if errors > 0 or warnings > 0:
			final_message_string = "Import finished with "
			if errors > 0:
				final_message_string += str(errors) + " error"
			if errors > 1:
				final_message_string += "s"
			if warnings > 0:
				if errors > 0:
					final_message_string += " and "
				final_message_string += str(warnings) + " warning"
				if warnings > 1:
					final_message_string += "s"
			final_message_string += "."
		print(final_message_string)
		if post_proc_error:
			print("Postprocessing was skipped due to some error.")
		if ct != null:
			ct.unload_custom_types()
	return ret
