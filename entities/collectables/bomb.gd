extends Collectable

func _on_collect(body):
	global.ammo.bomb += 1
	if body.hud:
		body.hud.update_weapons()
