extends CanvasLayer

signal entrance_chosen

onready var vbox = $Panel/ScrollContainer/VBoxContainer

var desired_entrance

func get_entrances(entrances):
	if entrances.size() == 1:
		yield(get_tree(), "idle_frame")
		finished(entrances[0].name)
		return
	for entrance in entrances:
		create_entrance_button(entrance.name)

func create_entrance_button(n):
	var button = Button.new()
	button.owner = vbox
	vbox.add_child(button)
	button.connect("pressed", self, "finished", [n])
	button.name = n
	button.text = n

func finished(n):
	global.next_entrance = n
	emit_signal("entrance_chosen")
