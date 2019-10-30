extends Node

var receivers = []

func send(event, params):
	for receiver in receivers:
		if receiver.event_name == event:
			receiver.receive(event, params)


func attach_event(event):
	if event.is_receiver: # Shouldn't have to check, but might as well be safe
		receivers.append(event)


func detach_event(event):
	var event_id = event.get_instance_id()
	# Find the event we want to detach
	var count = 0
	for receiver in receivers:
		if receiver.get_instance_id() == event_id:
			receivers.remove(count)
			continue
		else:
			count += 1
