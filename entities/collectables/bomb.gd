extends Collectable

func _on_collect(body):
	global.ammo.bomb += 1
	global.player.hud.update_weapons()
	
