extends Control

var can_change_key = false
var action_string

enum ACTIONS {UP, DOWN, LEFT, RIGHT, A, B, X, Y, START, QUICK_SAVE}

func _ready():
	global.connect("options_loaded", Callable(self, "update_options"))
	_set_keys()

func _input(event):
	# differentiate between keyboard keys and joypad buttons to allow to have both mapped at the same time
	if event is InputEventKey:
		if can_change_key:
			_change_key(event, InputEventKey)
			can_change_key = false
	elif event is InputEventJoypadButton:
		if can_change_key:
			_change_key(event, InputEventJoypadButton)
			can_change_key = false

func _change_key(new_key, event_class):
	# delete actions of the same type as the new key
	if !InputMap.action_get_events(action_string).is_empty():
		# walk backwards through the array as we may be deleting its items!
		for i in range(InputMap.action_get_events(action_string).size() - 1, -1, -1):
			var old_event = InputMap.action_get_events(action_string)[i]
			if (event_class == InputEventKey and old_event is InputEventKey) or (event_class == InputEventJoypadButton and old_event is InputEventJoypadButton):
				InputMap.action_erase_event(action_string, InputMap.action_get_events(action_string)[i])

	# remove the new key from any action it is assigned to right now
	for action in ACTIONS:
		if InputMap.action_has_event(action, new_key):
			InputMap.action_erase_event(action, new_key)

	# ass the new key to our currently selected action
	InputMap.action_add_event(action_string, new_key)
	var value = new_key.keycode if new_key is InputEventKey else new_key.button_index
	update_action(event_class, action_string, value)

	# update the UI
	_set_keys()

func _actions_join(array : Array, glue : String = "") -> String:
	# concatenates all elements of the input array, separated by the optional glue, into a single string
	var result : String = ""
	for index in range(0, array.size()):
		# keyboard and joypad have different methods to get their descriptive text...
		if array[index] is InputEventKey:
			result += array[index].as_text()
		elif array[index] is InputEventJoypadButton:
			result += "Joypad %s" % array[index].button_index
		else:
			result += "*unknown*"
		if index < array.size() - 1:
			result += glue
	return result

func _set_keys():
	for action in ACTIONS:
		var action_button = get_node("scroll/vbox/Action_" + str(action) + "/Button")
		var action_label = get_node("scroll/vbox/Action_" + str(action) + "/Label")

		if !action_button.is_connected("pressed", Callable(self, "_mark_button")):
			action_button.connect("pressed", Callable(self, "_mark_button").bind(str(action)))

		action_button.set_pressed(false)
		action_label.set_text(str(action))
		
		if !InputMap.action_get_events(action).is_empty():
			var btn_text = _actions_join(InputMap.action_get_events(action), ", ")
			action_button.set_text(btn_text)
		else:
			action_label.set_text("No Button!")

func _mark_button(target):
	can_change_key = true
	action_string = target
	for action in ACTIONS:
		if action != target:
			get_node("scroll/vbox/Action_" + str(action) + "/Button").set_pressed(false)

#############################
# SAVING & LOADING KEYBINDS #
#############################
func intialize_options():
	if not "keybinds" in global.options:
		global.options["keybinds"] = {}
	for event_type in ["InputEventKey", "InputEventJoypadButton"]:
		if not event_type in global.options.keybinds:
			global.options.keybinds[event_type] = {}

func update_options():
	intialize_options()

	for event_class in [InputEventKey, InputEventJoypadButton]:
		for keybind in global.options.keybinds[input_type_to_string(event_class)]:
			action_string = keybind
			var event = event_class.new()
			var stored_value = global.options.keybinds[input_type_to_string(event_class)][keybind]
			if event is InputEventKey:
				event.keycode = OS.find_keycode_from_string(str(stored_value))
			else:
				event.button_index = int(stored_value)
			_change_key(event, event_class)

func input_type_to_string(event_class):
	match event_class:
		InputEventKey:
			return "InputEventKey"
		InputEventJoypadButton:
			return "InputEventJoypadButton"
	return "unknown"

func update_action(event_class, action, value):
	intialize_options()

	global.options.keybinds[input_type_to_string(event_class)][action] = OS.get_keycode_string(value) if event_class == InputEventKey else value
