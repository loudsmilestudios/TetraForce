extends Area2D

export(String) var map
export(String) var entrance

onready var hole_fx = preload("res://effects/hole_falling.tscn").instance()

func _ready():
	add_to_group("entrances")
	connect("body_entered", self, "body_entered")

func body_entered(body):
	if body.is_in_group("player") && body.is_network_master():
		global.health = body.health
		body.position = position.linear_interpolate(position, 1)
		body.hide()
		body.state = "hole"
		get_parent().add_child(hole_fx)
		hole_fx.position = position
		sfx.play("fall")
		yield(get_tree().create_timer(1.25), "timeout")
		global.transition_type = true
		global.change_map(map, entrance)

