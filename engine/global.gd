extends Node

const schema_version = "0"
const server_version = "0"

const _user_dir = "user://"
const _save_location = "tetraforce"
const _save_file = "preferences.tf"

const default_host = "127.0.0.1"

var _user_prefs = {
	schema_version = "0",
	show_name_tags = true,
	host_address = default_host,
	display_name = "",
	skin = 0
	}

func _ready():
	var dir = Directory.new()
	if !dir.dir_exists(_get_save_dir()):
		dir.open(_user_dir)
		dir.make_dir(_get_save_dir())
		
	_load_from_preferences()
		
func _get_save_file():
	return _user_dir + _save_location + _save_file
	
func _get_save_dir():
	return _user_dir + _save_location

func _load_from_preferences():
	var saved = File.new()
		
	if !saved.file_exists(_get_save_file()):
		print ("File not found! Aborting...")
		_save_to_preferences()
		
		return

	saved.open(_get_save_file(), File.READ)
	
	var loaded = parse_json(saved.get_as_text())
	
	print("loaded save: ", saved.get_as_text())
		
	if loaded == null || loaded.empty():
		_save_to_preferences()
	elif loaded.schema_version != schema_version:
		_migrate_save(loaded)
	else:
		_user_prefs = loaded
		
	saved.close()
	
func _save_to_preferences():
	var saveGame = File.new()
	saveGame.open(_get_save_file(), File.WRITE)

	var line = JSON.print(_user_prefs)
	saveGame.store_string(String(line))
	saveGame.close()
	
# Using simple migration for now
# If we remove a key, currently that data is lost
# When needed, we can start migrating using the schema numbers to do more complicated migrations
func _migrate_save(loaded_save):
	for key in _user_prefs.keys():
		if loaded_save.has(key):
			_user_prefs[key] = loaded_save[key]
	
	_save_to_preferences()
	
func get_pref(key: String):
	if _user_prefs.has(key):
		return _user_prefs[key]
		
	return null
	
func set_pref(key: String, value):
	if _user_prefs.has(key):
		_user_prefs[key] = value
		
		_save_to_preferences()
