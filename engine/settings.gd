extends Node

# Update this whenever the _user_prefs or _user_controls dictionary are updated
const schema_version: String = "0"

# Update this for each release
const server_version: String = "0"

const _user_dir: String = "user://"
const _save_location: String = "tetraforce"
const _preference_file: String = "preferences.tf"

const default_host: String = "127.0.0.1"

var _user_controls: Dictionary = {
	"input.keys": {
		"UP": KEY_UP,
		"DOWN": KEY_DOWN,
		"LEFT": KEY_LEFT,
		"RIGHT": KEY_RIGHT,
		"A": KEY_X,
		"B": KEY_C,
		"X": KEY_V,
		"Y": KEY_B,
	},
	"input.axes": {
		"UP": [JOY_ANALOG_LY, -1.0],
		"DOWN": [JOY_ANALOG_LY, 1.0],
		"LEFT": [JOY_ANALOG_LX, -1.0],
		"RIGHT": [JOY_ANALOG_LX, 1.0]
	},
	"input.buttons": {
		"UP": JOY_DPAD_UP,
		"DOWN": JOY_DPAD_DOWN,
		"LEFT": JOY_DPAD_LEFT,
		"RIGHT": JOY_DPAD_RIGHT,
		"A": JOY_DS_A,
		"B": JOY_DS_B,
		"X": JOY_DS_X,
		"Y": JOY_DS_Y,
	}
}

var _user_prefs: Dictionary = {
	schema_version = "0",
	show_name_tags = true,
	host_address = default_host,
	display_name = "",
	skin = 0,
	controls = _user_controls
	}

func _ready() -> void:
	var dir = Directory.new()
	if !dir.dir_exists(_get_save_dir()):
		dir.open(_user_dir)
		dir.make_dir(_get_save_dir())
		
	_load_from_preferences()
		
func _get_save_file() -> String:
	return _user_dir + _save_location + _preference_file
	
func _get_save_dir() -> String:
	return _user_dir + _save_location

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
	elif loaded.schema_version != schema_version:
		_migrate_save(loaded)

	else:
		_user_prefs = loaded
	
	# uncomment this line if you updated the controls for testing
#	_user_prefs["controls"] = _user_controls
	
	_user_controls = _user_prefs["controls"]
		
	saved.close()
	
	load_input_map()
	
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
	
	_save_to_preferences()

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
	_user_controls = new_map
	set_pref("controls", _user_controls)
	
	load_input_map()
		
func load_input_map() -> void:
	InputMap.load_from_globals()
	
	var input_keys = _user_controls["input.keys"]
	
	for key in input_keys:
		if InputMap.has_action(key):
			var value = input_keys[key]
			var input_event = InputEventKey.new()
			input_event.scancode = value
			InputMap.action_add_event(key, input_event)
		else:
			printerr("Settings Error: Invalid input action '%s'" % key)

	var input_axes = _user_controls["input.axes"]
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

	var input_buttons = _user_controls["input.buttons"]
	for key in input_buttons.keys():
		if InputMap.has_action(key):
			var value = input_buttons[key]
			var input_event = InputEventJoypadButton.new()
			input_event.button_index = value
			InputMap.action_add_event(key, input_event)
		else:
			printerr("Settings Error: Invalid input action '%s'" % key)
