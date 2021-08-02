extends Area2D

export var music = ""
export var musicfx = ""
export var light = ""

func _ready():
	if music == "":
		music = get_parent().get_parent().music
	if musicfx == "":
		musicfx = get_parent().get_parent().musicfx
	if light == "":
		light = get_parent().get_parent().light
	
	yield(get_tree(), "idle_frame")
	
	for body in get_overlapping_bodies():
		if body.is_in_group("zoned"):
			body.zone = self

func get_enemies():
	var enemies = []
	for enemy in get_overlapping_bodies():
		if enemy is Enemy:
			enemies.append(enemy)
	return enemies

func get_players():
	var players = []
	for player in get_overlapping_bodies():
		if player is Player:
			players.append(player)
	return players
