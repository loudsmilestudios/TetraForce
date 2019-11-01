extends Event


export var event_key_id = 0 # Event Key ID for unlock event, which will be our entire payload

func _ready() -> void:
	payload = event_key_id


# We want to override the receive method to check if we have the correct key here
func receive(event, payload) -> void:
	# Check if we have the correct event_key_id, then call the actual event .receive method
	if payload == event_key_id:
		.receive(event, payload)
