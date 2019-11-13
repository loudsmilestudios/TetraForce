extends StaticBody2D

func _ready():
	z_index = -10
	network.connect("on_switch_toggled", self, "toggle_switch")

func toggle_switch():
	if network.toggle_block_state:
		$CollisionShape2D.disabled = true
		$Sprite.frame_coords.x = 1
	else:
		$CollisionShape2D.disabled = false
		$Sprite.frame_coords.x = 0
