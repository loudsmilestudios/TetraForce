extends Area2D

@export var map: String
@export var entrance: String

func _ready():
	add_to_group("entrances")
	connect("body_entered", Callable(self, "body_entered"))

func body_entered(body):
	if body.is_in_group("player") && body.is_multiplayer_authority():
		global.health = body.health
		body.position = position.lerp(position, 1)
		body.hide()
		body.state = "hole"
		var hole_fx = preload("res://effects/hole_falling.tscn").instantiate()
		get_parent().add_child(hole_fx)
		hole_fx.position = position
		sfx.play("fall")
		await get_tree().create_timer(1.25).timeout
		global.transition_type = true
		global.change_map(map, entrance)
