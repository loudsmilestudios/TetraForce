@tool
extends SceneTree

# Rebuild cached gameplay maps after changing the TMX post-processor:
# godot --headless --path . --script res://tests/reimport_maps.gd
var failures := 0
var imported := 0

func _initialize():
	call_deferred("run")

func run():
	reimport_maps("res://maps")
	print("Reimported %d gameplay maps (%d failures)" % [imported, failures])
	await process_frame
	await process_frame
	quit(1 if failures else 0)

func reimport_maps(path: String):
	var directory := DirAccess.open(path)
	for child in directory.get_directories():
		reimport_maps(path.path_join(child))
	for file in directory.get_files():
		if file.get_extension() != "tmx":
			continue
		var source := path.path_join(file)
		var config := ConfigFile.new()
		if config.load(source + ".import") != OK:
			failures += 1
			continue
		var creator = load("res://addons/YATI/TilemapCreator.gd").new()
		creator.set_add_id_as_metadata(true)
		var scene = creator.create(source)
		if !scene:
			failures += 1
			continue
		var processor = load("res://tiled/import.gd").new()
		scene = processor._post_process(scene)
		var packed := PackedScene.new()
		var error := packed.pack(scene)
		if error == OK:
			error = ResourceSaver.save(packed, config.get_value("remap", "path"))
		if error != OK:
			push_error("Reimport failed for %s: %s" % [source, error_string(error)])
			failures += 1
		else:
			imported += 1
		scene.free()
		processor.free()
