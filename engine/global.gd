extends Node

var player

onready var equips = {"B": "Sword", "X": "", "Y": ""}

var items = ["Sword", "Bow"]

var item_dict = {
	"Sword": "res://items/sword.tscn",
	"Bow": "res://items/arrow.tscn",
}

var item_icons = {
	"Sword": preload("res://ui/items/sword.png"),
	"Bow": preload("res://ui/items/bow.png"),
}

var next_entrance = "a"

signal options_loaded

var options = {
	player_data = {
		name="Chain",
		skin="res://player/player.png",
	}
}

func save_options():
	var save_options = File.new()
	save_options.open("user://options.json", File.WRITE)
	save_options.store_line(to_json(options))
	save_options.close()

func load_options():
	var load_options = File.new()
	if !load_options.file_exists("user://options.json"):
		return
	load_options.open("user://options.json", File.READ)
	var loaded_options = parse_json(load_options.get_line())
	for option in loaded_options.keys():
		options[option] = loaded_options.get(option)
	load_options.close()
	emit_signal("options_loaded")

func change_map(map, entrance):
	screenfx.play("fadewhite")
	yield(screenfx, "animation_finished")
	
	var old_map = network.current_map
	var root = old_map.get_parent()
	
	var new_map_path = "res://maps/" + map + ".tmx"
	var new_map = load(new_map_path).instance()
	
	old_map.queue_free()
	next_entrance = entrance
	root.add_child(new_map)

func get_item_name(item_path):
	return item_dict.keys()[item_dict.values().find(item_path)]

func get_item_path(item_name):
	return item_dict[item_name]
