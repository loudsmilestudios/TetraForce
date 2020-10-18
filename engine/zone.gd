extends Area2D

export var music = ""
export var musicfx = ""

func _ready():
	if music == "":
		music = get_parent().get_parent().music
	if musicfx == "":
		musicfx = get_parent().get_parent().musicfx
