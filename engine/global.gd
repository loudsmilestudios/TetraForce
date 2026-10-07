extends Node
const CENSOR_CHARS = "!@#$%^&*("
const VERSION_FILE = "res://semantic.version"
const SAVE_FORMAT = "user://saves/%s.tetraforce"

const INITIAL_AMMO = {
	"tetrans": 0,
	"arrow": 30,
	"bomb": 20,
}

const DEFAULT_EQUIPS = {"B": "Sword", "X": "", "Y": ""}
const DEFAULT_WEAPONS = ["Sword"]
const DEFAULT_ITEMS = []
const DEFAULT_PEARL = []
const DEFAULT_SPIRITPEARL = 0
const DEFAULT_HEALTH = 5

var version = null: get = get_version
var current_save_name = null
var blacklisted_words = []
var player
var equips = DEFAULT_EQUIPS.duplicate(true)
var weapons = DEFAULT_WEAPONS.duplicate(true)
var items = DEFAULT_ITEMS.duplicate(true)
var pearl = DEFAULT_PEARL.duplicate(true)
var health = DEFAULT_HEALTH
var max_health = DEFAULT_HEALTH
var spiritpearl = DEFAULT_SPIRITPEARL

var pvp = true

var changing_map = false
var transition_type = false

signal debug_update
signal save

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
		acquire_dialogue = ""},
	"Rock": {
		path = "res://entities/weapons/rock.tscn",
		icon = "",
		ammo_type = "",
		acquire_dialogue = ""},
	"Spike": {
		path = "res://entities/weapons/spike.tscn",
		icon = "",
		ammo_type = "",
		acquire_dialogue = ""}
}

var items_def = {
	"Lantern": {
		icon = preload("res://entities/player/items/lantern.png"),
		acquire_dialogue = "acquisition/acquire_lantern"
	},
	"SeaCharm": {
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
	"10 Tetrans": {
		icon = preload("res://entities/collectables/icons/tetran_blue_10.png"),
		acquire_dialogue = "acquisition/acquire_tetran_blue",
		ammo_type = "tetrans",
		amount = 10,
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

var ammo = INITIAL_AMMO.duplicate(true)
var next_entrance = ""

signal options_loaded

var options = {
	player_data = {
		name="Chain",
		skin="res://entities/player/chain.png",
	}
}
func _ready():
	load_blacklist()

func clean_session_data():
	ammo = INITIAL_AMMO.duplicate(true)
	current_save_name = null

	equips = DEFAULT_EQUIPS.duplicate(true)
	weapons = DEFAULT_WEAPONS.duplicate(true)
	items = DEFAULT_ITEMS.duplicate(true)
	pearl = DEFAULT_PEARL.duplicate(true)
	health = DEFAULT_HEALTH
	max_health = DEFAULT_HEALTH
	spiritpearl = DEFAULT_SPIRITPEARL

func load_blacklist():
	if FileAccess.file_exists("res://engine/blacklist.txt"):
		var blacklist_file = FileAccess.open("res://engine/blacklist.txt", FileAccess.READ)
		var word = blacklist_file.get_line()
		while word:
			blacklisted_words.append(word)
			word = blacklist_file.get_line()
	else:
		print("No word blocklist found!")

func value_in_blacklist(value : String):
	if "misc" in global.options:
		if "censor" in global.options.misc:
			if global.options.misc.censor == false:
				return false

	value = value.replace(" ", "").to_lower().replace("-","").replace(".","")
	for word in blacklisted_words:
		if word in value:
			return true
	return false

func filter_value(value : String):
	if value_in_blacklist(value):
		var new_value = ""
		for i in range(len(value)):
			new_value += CENSOR_CHARS[randi_range(0, len(CENSOR_CHARS) - 1)]
		return new_value
	return value

func _validate_save_dir():
	if not DirAccess.dir_exists_absolute("user://saves"):
		DirAccess.make_dir_absolute("user://saves")

func delete_save_data(save_name):
	_validate_save_dir()
	DirAccess.remove_absolute(SAVE_FORMAT % save_name)
	print("Deleted save: %s" % save_name)

func quicksave_game_data():
	print("Quicksaving...")
	var quicksave_name = get_quicksave_name()
	save_game_data(quicksave_name)

func get_quicksave_name():
	if current_save_name:
		return current_save_name + "_quicksave"
	else:
		var has_name = false
		var i = 0
		var save_name = "quicksave_%s" % i
		var all_saves = get_saves()
		while save_name in all_saves:
			i = i + 1
			save_name = "quicksave_%s" % i
		return save_name

func save_game_data(save_name):
	_validate_save_dir()

	var data = {
		"format" : "1",
		"states": network.states,
		"ammo" : ammo,
		"items" : {
			"equips": equips,
			"weapons": weapons,
			"items": items,
			"pearl" : pearl,
			"spiritpearl": spiritpearl,
		},
		"stats" : {
			"max_health" : max_health
		}
	}

	var save_file = FileAccess.open(SAVE_FORMAT % save_name, FileAccess.WRITE)
	if not save_file:
		return false
	save_file.store_line(Marshalls.utf8_to_base64(JSON.stringify(data)))
	if not "quicksave" in save_name:
		current_save_name = save_name
	emit_signal("save")
	print("Saved as: %s" % save_name)
	return true

func load_game_data(save_name):
	_validate_save_dir()

	if FileAccess.file_exists(SAVE_FORMAT % save_name):
		var save_file = FileAccess.open(SAVE_FORMAT % save_name, FileAccess.READ)
		var data = JSON.parse_string(Marshalls.base64_to_utf8(save_file.get_as_text()))
		if not data is Dictionary:
			return false
		for part in data:
			match part:
				"states":
					network.states = data["states"]
				"ammo":
					ammo = data["ammo"]
					# JSON parses all numbers as floats; ammo and currency are counts.
					for ammo_type in ammo:
						ammo[ammo_type] = int(ammo[ammo_type])
				"items":
					equips = data["items"]["equips"]
					weapons = data["items"]["weapons"]
					items = data["items"]["items"]
					pearl = data["items"]["pearl"]
					spiritpearl = int(data["items"]["spiritpearl"])
				"stats":
					max_health = data["stats"]["max_health"]
					health = max_health
		current_save_name = save_name
		print("Loaded save: %s" % save_name)
		return true
	else:
		return false

func get_saves():
	var save_files = []

	_validate_save_dir()
	for save_file in DirAccess.get_files_at("user://saves"):
		if save_file.ends_with(".tetraforce"):
			save_files.append(save_file.replace(".tetraforce",""))
	return save_files

func save_options():
	var save_options = FileAccess.open("user://options.json", FileAccess.WRITE)
	if save_options:
		save_options.store_line(JSON.stringify(options))

func load_options():
	if !FileAccess.file_exists("user://options.json"):
		options_loaded.emit()
		return
	var load_options = FileAccess.open("user://options.json", FileAccess.READ)
	var loaded_options = JSON.parse_string(load_options.get_line())
	if loaded_options is Dictionary:
		for option in loaded_options.keys():
			options[option] = loaded_options.get(option)
	options_loaded.emit()

func change_map(map, entrance):
	if changing_map:
		return
	changing_map = true

	sfx.fadeout_music()
	screenfx.play("fadewhite")
	await screenfx.animation_finished
	
	var old_map = network.current_map
	var root = old_map.get_parent()
	
	var new_map_path = "res://maps/" + map + ".tmx"
	var new_map = load(new_map_path).instantiate()
	
	old_map.queue_free()
	next_entrance = entrance
	root.add_child(new_map)
	
	emit_signal("debug_update")

func get_version():
	if !version:
		if FileAccess.file_exists(VERSION_FILE):
			var file = FileAccess.open(VERSION_FILE, FileAccess.READ)
			version = file.get_as_text()
		else:
			version = "custom build"
	return version
