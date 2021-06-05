extends Node

var player
var equips = {"B": "Sword", "X": "", "Y": ""}
var weapons = ["Sword"]
var items = []
var pearl =["Spiritpearl"]
var health = 5
var max_health = 5
var spiritpearl = 0

var changing_map = false
var transition_type = false

signal debug_update

var weapons_def = {
	"Sword": {
		path = "res://entities/weapons/sword.tscn",
		icon = preload("res://entities/weapons/icons/sword.png"),
		ammo_type = "",
		acquire_dialogue = ""},
	"Bow": {
		path = "res://entities/weapons/arrow.tscn",
		icon = preload("res://entities/weapons/icons/bow.png"),
		ammo_type = "arrow",
		acquire_dialogue = "acquisition/acquire_bow"},
	"Bomb": {
		path = "res://entities/weapons/bomb.tscn",
		icon = preload("res://entities/weapons/icons/bomb.png"),
		ammo_type = "bomb",
		acquire_dialogue = "acquisition/acquire_bombs"},
	"Bone": {
		path = "res://entities/weapons/bone.tscn",
		icon = "",
		ammo_type = "",
		acquire_dialogue = ""},
	"CannonBall": {
		path = "res://entities/weapons/cannonball.tscn",
		icon = "",
		ammo_type = "",
		acquire_dialogue = ""}
}

var items_def = {
	"Lantern": {
		icon = preload("res://entities/player/items/lantern.png"),
		acquire_dialogue = "acquisition/acquire_lantern"
	}
}

var ammo_def = {
	"100 Tetrans": {
		icon = preload("res://entities/collectables/icons/tetran_yellow_100.png"),
		acquire_dialogue = "acquisition/acquire_tetran_yellow",
		ammo_type = "tetrans",
		amount = 100,
	},
	"50 Tetrans": {
		icon = preload("res://entities/collectables/icons/tetran_black_50.png"),
		acquire_dialogue = "acquisition/acquire_tetran_black",
		ammo_type = "tetrans",
		amount = 50,
	},
	"20 Tetrans": {
		icon = preload("res://entities/collectables/icons/tetran_green_20.png"),
		acquire_dialogue = "acquisition/acquire_tetran_green",
		ammo_type = "tetrans",
		amount = 20,
	},
	"10 Arrows": {
		icon = preload("res://entities/collectables/icons/arrows.png"),
		acquire_dialogue = "acquisition/acquire_arrows_10",
		ammo_type = "arrow",
		amount = 10,
	},
	"10 Bombs": {
		icon = preload("res://entities/collectables/icons/bombs.png"),
		acquire_dialogue = "acquisition/acquire_bombs_10",
		ammo_type = "bomb",
		amount = 10,
	}
}

var dungeon_def = {
	"Key": {
		icon = preload("res://entities/collectables/key.png"),
		acquire_dialogue = "",
	}
}

var pearl_def = {
	"Spiritpearl": {
		path = "res://entities/collectables/spiritpearl.tscn",
		icon = preload("res://entities/collectables/spiritpearl.png"),
		acquire_dialogue = "acquisition/acquire_spirit_pearl"
	}
}

var ammo = {
	"tetrans": 0,
	"arrow": 30,
	"bomb": 20,
}

var next_entrance = ""

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
	if changing_map:
		return
	changing_map = true

	sfx.fadeout_music()
	screenfx.play("fadewhite")
	yield(screenfx, "animation_finished")
	
	var old_map = network.current_map
	var root = old_map.get_parent()
	
	var new_map_path = "res://maps/" + map + ".tmx"
	var new_map = load(new_map_path).instance()
	
	old_map.queue_free()
	next_entrance = entrance
	root.add_child(new_map)
	
	emit_signal("debug_update")
