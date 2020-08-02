extends Node

var player

onready var equips = {"B": "Sword", "X": "", "Y": ""}

var items = ["Sword", "Bow"]

var item_dict = {
	"Sword": "res://items/sword.tscn",
	"Bow": "res://items/arrow.tscn",
}

var item_icons = {
	"Sword": preload("res://ui/items/sword.png"),
	"Bow": preload("res://ui/items/bow.png"),
}

var next_entrance = "a"

func change_map(map, entrance):
	screenfx.play("fadewhite")
	yield(screenfx, "animation_finished")
	
	var old_map = network.current_map
	var root = old_map.get_parent()
	
	var new_map_path = "res://maps/" + map + ".tmx"
	var new_map = load(new_map_path).instance()
	
	old_map.queue_free()
	next_entrance = entrance
	root.add_child(new_map)

func get_item_name(item_path):
	return item_dict.keys()[item_dict.values().find(item_path)]

func get_item_path(item_name):
	return item_dict[item_name]
