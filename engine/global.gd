extends Node

var player

var next_entrance = "a"

func change_map(map, file_format, entrance):
	screenfx.play("fadewhite")
	yield(screenfx, "animation_finished")
	
	var old_map = network.current_map
	var root = old_map.get_parent()
	
	var new_map_path = "res://maps/" + map + file_format
	var new_map = load(new_map_path).instance()
	
	old_map.queue_free()
	next_entrance = entrance
	root.add_child(new_map)
