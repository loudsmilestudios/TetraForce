extends Event

export var key_id = 0 # For eventual key support, NYI


func receive(event, payload) -> void:
	if event == "unlock":
		get_parent().unlock(payload)


func send() -> void:
	event_bus.send("unlock", key_id)
