extends Switch

var entities_on: int = 0

func _update_sprite() -> void:
	if activated:
		$Sprite.frame_coords.x = 1
	else:
		$Sprite.frame_coords.x = 0


func _on_HitBox_body_entered(body: PhysicsBody2D) -> void:
	if body is Entity:
		entities_on += 1
		if entities_on == 1:
			update_state()
			$CooldownTimer.paused = true


func _on_HitBox_body_exited(body: PhysicsBody2D) -> void:
	if body is Entity:
		entities_on -= 1
		if entities_on == 0:
			$CooldownTimer.paused = false
			update_state()
