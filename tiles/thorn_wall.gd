extends StaticBody2D

@export var order: int = 0

var broken = false: set = set_broken

signal update_persistent_state

func _ready():
	if broken:
		queue_free()

func on_cannon_fired():
	var thorn_order = network.current_map.get_node("dungeon_handler").thorn_order
	var rect = global.player.camera.current_rect
	
	screenfx.play("fadein")
	await get_tree().create_timer(1).timeout
	$AnimationPlayer.play("break")
	network.peer_call($AnimationPlayer, "play", ["break"])
	set_broken(true)
	network.peer_call(self, "set_broken", [true])
	emit_signal("update_persistent_state")
	await get_tree().create_timer(0.6).timeout
	
	sfx.play("explosion")
	global.player.camera.on_screen_shake()
	await $AnimationPlayer.animation_finished
	await get_tree().create_timer(0.4).timeout
	
	screenfx.play("fadewhite")
	await screenfx.animation_finished
	
	global.player.camera.target = global.player
	global.player.camera.set_limits(rect)
	await get_tree().create_timer(0.2).timeout
	
	screenfx.play("fadein")
	await screenfx.animation_finished
	
	global.player.state = "default"
	if global.player.is_in_group("invunerable"):
		global.player.remove_from_group("invunerable")
		
func set_broken(value):
	broken = value
