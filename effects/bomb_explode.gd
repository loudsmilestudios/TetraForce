extends Weapon

func start():
	$Hitbox.connect("body_entered", self, "body_entered")
	var shooter = get_parent()
	get_parent().remove_child(self)
	shooter.get_parent().add_child(self)
	position = shooter.position
	TYPE = "BOMB"

func body_entered(body):
	if body is Entity:
		damage(body)
