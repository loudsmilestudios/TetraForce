extends Control

@export var main_path: NodePath
@export var mode = SaveManager.SAVE_MODE.LOAD # (SaveManager.SAVE_MODE)
@export var show_return_button: bool = false
var manager : get = get_manager

@onready var input_overlay = $InputOverlay
@onready var confirm_overlay = $confirm_overlay

func _ready():

	if input_overlay:
		input_overlay.hide()
		$saves.input_overlay = input_overlay
		input_overlay.connect("submission", Callable($saves, "on_save_name_entered"))
	if confirm_overlay:
		confirm_overlay.hide()
		$saves.confirm_overlay = confirm_overlay
		confirm_overlay.connect("submission", Callable($saves, "on_confirmation"))
	
	if main_path:
		$saves.main = get_node(main_path)
	if mode:
		$saves.default_mode = mode
	
	if show_return_button:
		$return.show()
	else:
		$return.hide()

func get_manager():
	return $saves

func grab_focus(keep_if_already_focused := false):
	$return.grab_focus(keep_if_already_focused)
