extends Area2D

export(String) var map
export(String) var player_position
export(String) var entrance

func _ready():
	add_to_group("entrances")
	connect("body_entered", self, "body_entered")
	spritedir()

func body_entered(body):
	if body.is_in_group("player") && body.is_network_master():
		global.health = body.health
		body.state = "interact"
		global.change_map(map, entrance)

func spritedir():
	if player_position == "up":
		self.rotation_degrees = 0
	elif player_position == "right":
		self.rotation_degrees = 90
	elif player_position == "down":
		self.rotation_degrees = 180
	elif player_position == "left":
		self.rotation_degrees = 270
