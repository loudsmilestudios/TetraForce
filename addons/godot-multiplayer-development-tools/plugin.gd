tool
extends EditorPlugin

const SETTINGS_BASE = "tools/multiplayer_devtools/"

var multistart_button: Button

var default_settings = {"multistart/instance_count": 2}


func _enter_tree():
	multistart_button = Button.new()
	multistart_button.text = "Multistart"

	# Set default config
	for setting in default_settings:
		if not ProjectSettings.has_setting(SETTINGS_BASE + setting):
			ProjectSettings.set_setting(SETTINGS_BASE + setting, default_settings[setting])

	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, multistart_button)


func _ready():
	multistart_button.connect("button_down", self, "launch_multiplayer_setup")


func _exit_tree():
	remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, multistart_button)

	# Clear settings
	for setting in default_settings:
		if ProjectSettings.has_setting(SETTINGS_BASE + setting):
			ProjectSettings.clear(SETTINGS_BASE + setting)


func launch_multiplayer_setup():
	for i in range(ProjectSettings.get_setting(SETTINGS_BASE + "multistart/instance_count")):
		var window_pos = Vector2(8 * i, (8 * i) + 64)
		if i == 0:
			window_pos.x = 0
			window_pos.y = 0
		elif i == 1:
			window_pos.x = (
				OS.get_screen_size().x
				- ProjectSettings.get_setting("display/window/size/width")
			)
			window_pos.y = 0
		elif i == 2:
			window_pos.x = (
				OS.get_screen_size().x
				- ProjectSettings.get_setting("display/window/size/width")
			)
			window_pos.y = (
				OS.get_screen_size().y
				- ProjectSettings.get_setting("display/window/size/height")
			)
		elif i == 3:
			window_pos.x = 0
			window_pos.y = (
				OS.get_screen_size().y
				- ProjectSettings.get_setting("display/window/size/height")
			)

		var window_pos_str = "%s,%s" % [window_pos.x, window_pos.y]
		OS.execute(OS.get_executable_path(), ["--path", ".", "--position", window_pos], false)

	get_editor_interface().play_main_scene()
