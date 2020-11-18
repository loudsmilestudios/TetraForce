extends Weapon

func start():
	$AnimationPlayer.play("tick")
	var shooter = get_parent()
	get_parent().remove_child(self)
	shooter.get_parent().add_child(self)
	position = shooter.position
	sfx.play("bow")

func explode():
	var explosion = preload("res://effects/bomb_explode.tscn").instance()
	add_child(explosion)
	explosion.start()
