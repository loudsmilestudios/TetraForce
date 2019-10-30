extends Node

class_name Event

export var event_name := "" # Name of the event, used by the event_bus

export var is_sender := false # Is this event a sender?
export var trigger_signal := "" # Signal on the parent that will trigger the event


export var is_receiver := false # Is this event a receiver?
export var listen_function := "" # Which function should be triggered on the parent when an event is received


var payload # Payload of the event, can be anything right now


func _ready() -> void:
	if is_receiver:
		event_bus.attach_event(self)
		connect("tree_exiting", self, "_on_Event_tree_exiting")
	
	if is_sender:
		get_parent().connect(trigger_signal, self, "send")


func send() -> void:
	event_bus.send(event_name, payload)


func receive(event, payload) -> void:
	if get_parent().has_method(listen_function):
		get_parent().call(listen_function, payload)


func _on_Event_tree_exiting() -> void:
	if is_receiver:
		event_bus.detach_event(self)
