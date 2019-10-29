extends Powerup

var heal_amount = 1

func on_pickup(player):
	if player.health < player.MAX_HEALTH:
		player.health = min(player.health + heal_amount, player.MAX_HEALTH)
		rpc("delete")
