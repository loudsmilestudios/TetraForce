class_name SaveManager
extends Control

signal exit

export(PackedScene) var save_display

var main = null
var input_overlay = null
var confirm_overlay = null
onready var save_holder = $VBoxContainer
onready var new_button = $VBoxContainer/ChangeMode/HSplitContainer/NewButton
onready var delete_button = $VBoxContainer/ChangeMode/HSplitContainer/DeleteSaveButton
onready var container = get_parent()

enum SAVE_MODE { VIEW = 0, SAVE = 1, LOAD = 2, DELETE = 3 }

var default_mode = SAVE_MODE.LOAD
var current_mode = default_mode
var pending_confirm_source = null

func _ready():
	new_button.connect("button_down", self, "on_new")
	delete_button.connect("button_down", self, "_on_manage_saves_button_down")

	refresh_saves()
	
func refresh_saves():
	current_mode = default_mode
	for child in save_holder.get_children():
		if child is SaveDisplay:
			child.queue_free()
	
	for save in global.get_saves():
		var node : SaveDisplay = save_display.instance()
		node.save_name = save
		node.mode = current_mode
		save_holder.add_child(node)
		save_holder.move_child(node, 0)
		node.connect("clicked", self, "set_mode", [default_mode])
		node.connect("action_complete", self, "on_action_complete")
		node.connect("request_confirmation", self, "on_confirm_request")
		node.connect("clicked", self, "play_interact_sfx")
	update_gui()

func _process(delta):
	delete_button.visible == (len(global.get_saves()) <= 0)

func on_confirm_request(source, message):
	pending_confirm_source = source
	confirm_overlay.set_message(message)
	hide()
	confirm_overlay.open()

func on_confirmation(result):
	if result:
		pending_confirm_source.on_action(true)
	show()

func on_action_complete():
	match default_mode:
		SAVE_MODE.SAVE:
			if default_mode == current_mode:
				emit_signal("exit")
		SAVE_MODE.LOAD:
			on_new()

func on_new():
	match default_mode:
		SAVE_MODE.LOAD:
			if main:
				main._on_quickstart_pressed()
			else:
				printerr("Reference to `main` not set! Cannot start game.")
		SAVE_MODE.SAVE:
			if input_overlay:
				hide()
				input_overlay.open()
		_:
			printerr("Move `%s` is not supported by player select!" % default_mode)

func on_save_name_entered(save_name):
	global.save_game_data(save_name)
	show()
	emit_signal("exit")

func set_mode(mode):
	current_mode = mode
	for child in save_holder.get_children():
		if child is SaveDisplay:
			child.mode = mode
	update_gui()

func _on_manage_saves_button_down():
	if(current_mode != SAVE_MODE.DELETE):
		set_mode(SAVE_MODE.DELETE)
	else:
		set_mode(default_mode)

func update_gui():
	match default_mode:
		SAVE_MODE.LOAD:
			new_button.text = "New Game"
		SAVE_MODE.SAVE:
			new_button.text = "New Save"
	match current_mode:
		SAVE_MODE.LOAD, SAVE_MODE.SAVE:
			delete_button.text = "Delete Save"
		SAVE_MODE.DELETE:
			delete_button.text = "Cancel"
		_:
			printerr("'%s' cannot handle SAVE_MODE `%s`" % [delete_button.get_path(), current_mode])
			delete_button.text = "???"

func close():
	if(input_overlay and input_overlay.visible):
		input_overlay.close()
		show()
		new_button.grab_focus()
	elif(confirm_overlay and confirm_overlay.visible):
		confirm_overlay.close()
		show()
		new_button.grab_focus()
	else:
		emit_signal("exit")

func play_interact_sfx():
	sfx.play("sword3")
