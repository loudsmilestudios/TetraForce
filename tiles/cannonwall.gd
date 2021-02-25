extends StaticBody2D

func on_explosion():
	if network.is_map_host():
		global.player.camera.on_screen_shake()
		$AnimationPlayer.play("explosion")
		sfx.play("explosion")
		$Sprite.hide()
	else:
		network.peer_call_id(network.get_map_host(), self, "on_explosion", [])


func _on_AnimationPlayer_animation_finished(explosion):
	queue_free()
