extends Node

var player
var equips = {"B": "Sword", "X": "", "Y": ""}
var items = ["Sword", "Bow"]

class ItemInfo:
	var path : String
	var icon : Texture
	var ammo_type : String = ""
	
	func _init(p,i,a):
		path = p
		icon = i
		ammo_type = a

var item_list = {}

var ammo = {
	"arrow": 30,
}

var next_entrance = "a"

signal options_loaded

var options = {
	player_data = {
		name="Chain",
		skin="res://player/player.png",
	}
}

func _ready():
	define_items()

func define_items():
	item_list["Sword"] = ItemInfo.new("res://items/sword.tscn", preload("res://ui/items/sword.png"), "")
	item_list["Bow"] = ItemInfo.new("res://items/arrow.tscn", preload("res://ui/items/bow.png"), "arrow")

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
