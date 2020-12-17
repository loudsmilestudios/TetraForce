extends Area2D

var player

func _ready():
	add_to_group("entity_detect")
	set_process(false)

func _process(delta):
	if !is_instance_valid(player):
		remove_from_group("entity_detect")
		queue_free()
	
	position = player.current_zone.position + player.current_zone.get_node("CollisionShape2D").shape.extents
	scale = player.current_zone.get_node("CollisionShape2D").shape.extents / $CollisionShape2D.shape.extents
