extends Node

func on_return():
	sfx.play("sword3")
	self.queue_free()

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