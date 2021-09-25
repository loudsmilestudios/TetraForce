extends Control

const OPTIONS_PATH = "res://ui/options/options_panel.tscn"

onready var hud = get_parent()
onready var main = get_tree().get_root().get_node_or_null("main")
onready var saves = hud.get_node("saves")

func _ready():
	$VBoxContainer.get_child(0).grab_focus()
	saves.manager.connect("exit", self, "on_return")

func _input(event):
	if Input.is_action_just_pressed("ESC"):
		on_return()

func show_game_map():
	network.current_map.show()

func on_any_button_pressed():
	sfx.play("sword3")

func on_return():
	on_any_button_pressed()
	exit_save()
	get_parent().show_esc_menu()

func on_exit_to_menu():
	on_any_button_pressed()
	if main:
		main.end_game()
	else:
		printerr("'%s' screen could not find `main` node!" % name)
	self.queue_free()
	
func on_options():
	on_any_button_pressed()
	var options : Control = hud.get_node_or_null("options_panel")
	if options:
		options.queue_free()
	else:
		options = preload(OPTIONS_PATH).instance()
		hud.add_child(options)

func on_save():
	saves.show()
	saves.grab_focus()
	saves.manager.refresh_saves()
	hide()

func exit_save():
	saves.hide()

func on_quit_game():
	on_any_button_pressed()
	get_tree().quit(0)
