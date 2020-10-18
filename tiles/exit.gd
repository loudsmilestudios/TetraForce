extends Area2D

export(String) var map
export(String) var player_position
export(String) var entrance

func _ready():
	add_to_group("entrances")
	connect("body_entered", self, "body_entered")

func body_entered(body):
	if body.is_in_group("player") && body.is_network_master():
		body.state = "interact"
		global.change_map(map, entrance)
