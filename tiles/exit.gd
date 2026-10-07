extends Area2D

@export var map: String
@export var player_position: String
@export var entrance: String

func _ready():
	add_to_group("entrances")
	connect("body_entered", Callable(self, "body_entered"))
	spritedir()

func body_entered(body):
	if body.is_in_group("player") && body.is_multiplayer_authority():
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
