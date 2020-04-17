extends Switch

func _update_sprite() -> void:
	if activated:
		$Sprite.frame_coords.x = 1
	else:
		$Sprite.frame_coords.x = 0

func _on_HitBox_area_entered(area: Area2D) -> void:
	if area.get_parent() is Item:
		update_state()
