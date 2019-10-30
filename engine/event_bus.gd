extends Node

var listeners = []

func send(event, payload):
	for listener in listeners:
		if listener.event_name == event:
			listener.receive(event, payload)


func attach_event(event):
	if event.is_listener: # Shouldn't have to check, but might as well be safe
		listeners.append(event)


func detach_event(event):
	var event_id = event.get_instance_id()
	# Find the event we want to detach
	var count = 0
	for listener in listeners:
		if listener.get_instance_id() == event_id:
			listeners.remove(count)
			continue
		else:
			count += 1
