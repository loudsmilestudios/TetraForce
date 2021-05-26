extends Collectable

func _on_collect(body):
	global.ammo.arrow += 1
	global.player.hud.update_weapons()
	
