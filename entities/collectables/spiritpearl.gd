extends Collectable

var max_pearls = 4
var player_hud = global.player.hud

signal update_persistent_state

func add_pearl():
	if network.is_map_host():
		count_pearl()
		if global.spiritpearl >= max_pearls:
			global.max_health += 1
			on_full_slate()
			global.spiritpearl = 0
	else:
		network.peer_call(self, "count_pearl")
		if global.spiritpearl >= max_pearls:
			global.max_health += 1
			on_full_slate()
			global.spiritpearl = 0

func count_pearl():
	global.spiritpearl += 1
	network.peer_call(self, "add_pearl", [global.spiritpearl])
	
func on_full_slate():
	var newheart = Sprite.new()
	newheart.texture = player_hud.hearts.texture
	newheart.hframes = player_hud.hearts.hframes
	player_hud.hearts.add_child(newheart)
	player_hud.update_hearts()
	player_hud.timer.start()

