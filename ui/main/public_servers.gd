extends Control

export(int) var number_of_servers = 2
export(NodePath) var _main
export(NodePath) var _button_container

export(Array, String) var name_gen_first_part = [ "Tetra", "First", "Second", "Third", "Fourth" ]
export(Array, String) var name_gen_middle_part = [ "of" ]
export(Array, String) var name_gen_end_part = [ "Friends", "Force" ]
export(Array, String) var name_gen_any_part = [ "Sword", "Bow", "Dungeon", "Fire", "Doom", "Chain",
		"Knot", "Key", "Pirate", "Bat", "Knawblin", "Cucukin", "Village" ]

var main : Main
var button_container : Control

func _ready():
	main = get_node(_main)
	button_container = get_node(_button_container)
	
	for child in button_container.get_children():
		child.queue_free()
	
	for i in range(number_of_servers):
		var server_name = generate_server_name(i)
		button_container.add_child(create_server_button("#%s %s" % [i+1, server_name],server_name))

func create_server_button(server_label : String, server_name : String) -> Node:
	var button = Button.new()
	button.connect("button_down", main, "join_aws", [server_name])
	button.align = Button.ALIGN_LEFT
	button.text = server_label
	return button

func get_version_as_int() -> int:
	var spb = StreamPeerBuffer.new()
	spb.data_array = global.get_version().to_utf8()
	return spb.get_64()

func generate_server_name(randomizer_seed : int) -> String:
	var rand = RandomNumberGenerator.new()
	rand.seed = randomizer_seed + get_version_as_int()
	var possible_first = name_gen_first_part + name_gen_any_part
	var first = possible_first[rand.randi_range(0,len(possible_first)-1)]
	var possible_middle = name_gen_middle_part + name_gen_any_part
	var middle = possible_middle[rand.randi_range(0,len(possible_middle)-1)]
	var possible_end = name_gen_end_part + name_gen_any_part
	var end = possible_end[rand.randi_range(0,len(possible_end)-1)]
	return first + "-" + middle + "-" + end
