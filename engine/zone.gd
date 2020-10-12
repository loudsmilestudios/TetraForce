extends Area2D

export var music = ""

func _ready():
	if music == "":
		music = get_parent().get_parent().default_song
