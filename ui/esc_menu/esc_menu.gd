extends Node

func _ready():
	$VBoxContainer.get_child(0).grab_focus()

func _input(event):
	if Input.is_action_just_pressed("ESC"):
		on_return()

func on_return():
	sfx.play("sword3")
	get_parent().show_esc_menu()

func on_exit_to_menu():
	sfx.play("sword3")
	var main = get_tree().get_root().get_node_or_null("main")
	if main:
		main.end_game()
	else:
		printerr("'%s' screen could not find `main` node!" % name)
	self.queue_free()

func on_quit_game():
	sfx.play("sword3")
	get_tree().quit(0)
