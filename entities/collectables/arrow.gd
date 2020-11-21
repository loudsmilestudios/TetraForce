extends Collectable

func _on_collect(body):
	global.ammo.arrow += 1
	body.hud.update_weapons()
