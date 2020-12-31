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

func get_enemies():
	var overlapping_enemies = []
	for body in get_overlapping_bodies():
		if body is Enemy:
			overlapping_enemies.append(body)
	return overlapping_enemies
