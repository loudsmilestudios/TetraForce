extends Area2D

export(String) var map
export(String) var player_position
export(String) var entrance
export(float) var collider_height = 1
export(float) var collider_width = 1

func _ready():
	add_to_group("entrances")
	connect("body_entered", self, "body_entered")
	scale = Vector2(collider_width, collider_height)
	position -= Vector2((collider_width-1)*8, (collider_height-1)*8)

func body_entered(body):
	if body.is_in_group("player") && body.is_network_master():
		body.state = "interact"
		global.change_map(map, entrance)
