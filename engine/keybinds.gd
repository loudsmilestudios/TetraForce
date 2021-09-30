extends Control

var can_change_key = false
var action_string

enum ACTIONS {UP, DOWN, LEFT, RIGHT, A, B, X, Y, START, QUICK_SAVE}

func _ready():
	global.connect("options_loaded", self, "update_options")
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

func _change_key(new_key, type):
	# delete actions of the same type as the new key
	if !InputMap.get_action_list(action_string).empty():
		# walk backwards through the array as we may be deleting its items!
		for i in range(InputMap.get_action_list(action_string).size() - 1, -1, -1):
			if InputMap.get_action_list(action_string)[i] is type:
				InputMap.action_erase_event(action_string, InputMap.get_action_list(action_string)[i])

	# remove the new key from any action it is assigned to right now
	for action in ACTIONS:
		if InputMap.action_has_event(action, new_key):
			InputMap.action_erase_event(action, new_key)

	# ass the new key to our currently selected action
	InputMap.action_add_event(action_string, new_key)
	update_action(type, action_string, new_key.scancode)

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
			# result += "JOY_BUTTON_" + str(array[index].get_button_index())
			result += Input.get_joy_button_string(array[index].get_button_index())
		else:
			result += "*unknown*"
		if index < array.size() - 1:
			result += glue
	return result

func _set_keys():
	for action in ACTIONS:
		var action_button = get_node("scroll/vbox/Action_" + str(action) + "/Button")
		var action_label = get_node("scroll/vbox/Action_" + str(action) + "/Label")

		if !action_button.is_connected("pressed", self, "_mark_button"):
			action_button.connect("pressed", self, "_mark_button", [str(action)])

		action_button.set_pressed(false)
		action_label.set_text(str(action))
		
		if !InputMap.get_action_list(action).empty():
			var btn_text = _actions_join(InputMap.get_action_list(action), ", ")
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
	for type in ["InputEventKey", "InputEventJoypadButton"]:
		if not type in global.options.keybinds:
			global.options.keybinds[type] = {}

func update_options():
	intialize_options()

	for type in [InputEventKey, InputEventJoypadButton]:
		for keybind in global.options.keybinds[input_type_to_string(type)]:
			action_string = keybind
			var event = type.new()
			event.scancode = OS.find_scancode_from_string(global.options.keybinds[input_type_to_string(type)][keybind])
			_change_key(event, type)

func input_type_to_string(type):
	match type:
		InputEventKey:
			return "InputEventKey"
		InputEventJoypadButton:
			return "InputEventJoypadButton"
	return "unknown"

func update_action(type, action, value):
	intialize_options()

	global.options.keybinds[input_type_to_string(type)][action] = OS.get_scancode_string(value)
