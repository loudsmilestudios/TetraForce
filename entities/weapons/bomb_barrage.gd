extends Weapon

var location = Vector2.ZERO

func start():
	if "location" in self.data:
		location = self.data["location"]
	barrage(location)

func explode():
	var explosion = preload("res://effects/bomb_explode.tscn").instance()
	add_child(explosion)
	explosion.start()
	
func barrage(location):
	var shooter = get_parent()
	$AnimationPlayer.play("fall")
	get_parent().remove_child(self)
	shooter.get_parent().add_child(self)
	global_position = shooter.global_position + location
	sfx.play("bow")
