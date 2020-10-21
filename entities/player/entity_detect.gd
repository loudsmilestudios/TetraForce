extends Area2D

var player

func _ready():
	add_to_group("entity_detect")

func _process(delta):
	if !is_instance_valid(player):
		remove_from_group("entity_detect")
		queue_free()
	
	position = player.camera.get_camera_screen_center()
