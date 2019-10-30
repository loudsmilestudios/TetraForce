extends Node

var senders = []
var receivers = []


func send(event, params):
	for receiver in receivers:
		receiver.receive(event, params)


func attach_event(event):
	if event.is_sender:
		senders.append(event)
		event.connect("send", self, "_send")
		
	if event.is_receiver:
		receivers.append(event)
	
	pass

func detach_event(event):
	var event_id = event.get_instance_id()
	print('detaching...', event)
	if event.is_sender:
		var count = 0
		for sender in senders:
			if sender.get_instance_id() == event_id:
				senders.remove(count)
				print('removing at index ', count)
				continue
			else:
				count += 1
				print('more counting')
		
	if event.is_receiver:
		var count = 0
		for receiver in receivers:
			if receiver.get_instance_id() == event_id:
				receivers.remove(count)
				print('removing at index ', count)
				
				continue
			else:
				count += 1
		pass