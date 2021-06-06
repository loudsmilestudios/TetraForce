extends Collectable

func _on_collect(body):
	body.health += 1
	if body.hud:
		body.hud.update_hearts()
