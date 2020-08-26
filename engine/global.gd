extends Node

var player
var equips = {"B": "Sword", "X": "", "Y": ""}
var weapons = ["Sword"]

class WeaponInfo:
	var path : String
	var icon : Texture
	var ammo_type : String
	var acquire : String
	
	func _init(use_path,icon_texture,ammo="",acquire_path=""):
		path = use_path
		icon = icon_texture
		ammo_type = ammo
		acquire = acquire_path

var weapon_def = {
	# "WeaponName": WeaponInfo.new(
	# "path/to/weapon.tscn",
	# preload("path/to/icon.png"),
	# "ammo_type"
	# "acquire_dialogue"),
	
	"Sword": WeaponInfo.new(
		"res://entities/weapons/sword.tscn",
		preload("res://entities/weapons/icons/sword.png"),
		"",
		""),
	"Bow": WeaponInfo.new(
		"res://entities/weapons/arrow.tscn",
		preload("res://entities/weapons/icons/bow.png"),
		"arrow",
		"acquire_bow"),
}

var ammo = {
	"arrow": 30,
}

var next_entrance = "a"

signal options_loaded

var options = {
	player_data = {
		name="Chain",
		skin="res://entities/player/chain.png",
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
