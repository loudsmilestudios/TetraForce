extends Node

class_name Event

var TYPE = "EVENT"


export var is_sender := false
export var event_name := ""
export var trigger := ""


export var is_receiver := false


func _ready() -> void:
	print('adding me to eventbus')
	event_bus.attach_event(self)
	
	connect("tree_exiting", self, "_on_Event_tree_exiting")
	
	if is_sender:
		get_parent().connect(trigger, self, "send")


func send() -> void:
	pass

func receive(event, payload) -> void:
	pass


func _on_Event_tree_exiting() -> void:
	print('I should be gone from bus')
	event_bus.detach_event(self)
	pass # Replace with function body.
