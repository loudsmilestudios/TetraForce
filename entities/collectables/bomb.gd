extends Collectable

func _on_collect(body):
	global.ammo.bomb += 1
	body.hud.update_weapons()
