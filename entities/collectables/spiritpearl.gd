extends Collectable

var max_pearls = 4
var spiritpearls = 0
var player_hud = global.player.hud

signal update_persistent_state

func _ready():
	network.peer_call(self, "set_spiritpearls", [spiritpearls])

func count_pearl():
	network.peer_call(self, "set_spiritpearls", [spiritpearls + 1])
	set_spiritpearls(spiritpearls + 1)
	emit_signal("update_persistent_state")
	if global.spiritpearl >= max_pearls:
		global.max_health += 1
		on_full_slate()
		set_spiritpearls(0)
	
func on_full_slate():
	var newheart = Sprite.new()
	newheart.texture = player_hud.hearts.texture
	newheart.hframes = player_hud.hearts.hframes
	player_hud.hearts.add_child(newheart)
	player_hud.update_hearts()
	player_hud.timer.start()

func set_spiritpearls(amount):
	spiritpearls = amount
	global.spiritpearl = spiritpearls

