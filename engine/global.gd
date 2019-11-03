extends Node

func get_item_name(item_path):
	return item_dict.keys()[item_dict.values().find(item_path)]

func get_item_path(item_name):
	return item_dict[item_name]


var item_dict = {
	"Sword": "res://items/sword.tscn",
	"Bow": "res://items/arrow.tscn",
}
