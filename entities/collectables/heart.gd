extends Collectable

func _on_collect(body):
	body.health += 1
	global.player.hud.update_hearts()
