extends Node

# Update this for each release
const SERVER_VERSION: String = "0"

# Update this whenever the _user_prefs or _user_controls dictionary are updated
const SCHEMA_VERSION: String = "1"
const CONTROLS_SCHEMA_VERSION: String = "2"

const _user_dir: String = "user://"
const _preference_file: String = "preferences.json"

const default_host: String = "127.0.0.1"


onready var _user_prefs: Dictionary = {
	schema_version = "0",
	show_name_tags = true,
	host_address = default_host,
	display_name = "",
	skin = 0,
	controls = controller.default
	}

func _ready() -> void:
	var dir = Directory.new()
	if !dir.dir_exists(_get_save_dir()):
		dir.open(_user_dir)
		dir.make_dir(_get_save_dir())
		
	_load_from_preferences()
		
func _get_save_file() -> String:
	return _user_dir + _preference_file
	
func _get_save_dir() -> String:
	return _user_dir

func _load_from_preferences() -> void:
	var saved = File.new()
		
	if !saved.file_exists(_get_save_file()):
		_save_to_preferences()

	saved.open(_get_save_file(), File.READ)
	
	var loaded = parse_json(saved.get_as_text())
	
	# Debugging loaded saves
	print("loaded save: ", saved.get_as_text())
	
	if loaded == null || loaded.empty():
		_save_to_preferences()
	elif !loaded.has("schema") || loaded["schema"] != SCHEMA_VERSION:
		_migrate_save(loaded)
	else:
		_user_prefs = loaded
	
	_load_controls(_user_prefs["controls"])
		
	saved.close()
	
func _save_to_preferences() -> void:
	var saveGame = File.new()
	saveGame.open(_get_save_file(), File.WRITE)

	var line = JSON.print(_user_prefs)
	saveGame.store_string(String(line))
	saveGame.close()
	
# Using simple migration for now
# If we remove a key, currently that data is lost
# When needed, we can start migrating using the schema numbers to do more complicated migrations
func _migrate_save(loaded_save) -> void:
	for key in _user_prefs.keys():
		if loaded_save.has(key):
			_user_prefs[key] = loaded_save[key]
		
	_user_prefs["schema"] = SCHEMA_VERSION
	_save_to_preferences()
	
func _load_controls(loaded_controls) -> void:
	var schema_key = "schema"
	
	if !loaded_controls.has(schema_key) || loaded_controls[schema_key] != CONTROLS_SCHEMA_VERSION:
		# migrate controller logic if needed
		_user_prefs["controls"] =  controller.default
		_save_to_preferences()
	
	load_input_map(loaded_controls)

func get_pref(key: String):
	if _user_prefs.has(key):
		return _user_prefs[key]
		
	printerr( "Key `%s` not found! " % key)
	
	return null
	
func set_pref(key: String, value) -> void:
	if _user_prefs.has(key):
		_user_prefs[key] = value
		
		_save_to_preferences()
		
func save_input_map(new_map: Dictionary) -> void:
	set_pref("controls", new_map)
	
	load_input_map(new_map)
		
func load_input_map(loaded_controls) -> void:
	InputMap.load_from_globals()
	
	var input_keys = loaded_controls["input.keys"]
	
	for key in input_keys:
		if InputMap.has_action(key):
			var value = input_keys[key]
			var input_event = InputEventKey.new()
			input_event.scancode = value
			InputMap.action_add_event(key, input_event)
		else:
			printerr("Settings Error: Invalid input action '%s'" % key)

	var input_axes = loaded_controls["input.axes"]
	for key in input_axes.keys():
		if InputMap.has_action(key):
			var value = input_axes[key]
			if value is Array and value.size() == 2:
				var input_event = InputEventJoypadMotion.new()
				input_event.axis = value[0]
				input_event.axis_value = value[1]
				InputMap.action_add_event(key, input_event)
			else:
				printerr("Settings Error: Invalid axis definition '%s'" % key)
		else:
			printerr("Settings Error: Invalid input action '%s'" % key)

	var input_buttons = loaded_controls["input.buttons"]
	for key in input_buttons.keys():
		if InputMap.has_action(key):
			var value = input_buttons[key]
			var input_event = InputEventJoypadButton.new()
			input_event.button_index = value
			InputMap.action_add_event(key, input_event)
		else:
			printerr("Settings Error: Invalid input action '%s'" % key)
