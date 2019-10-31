extends Area2D

"""
Unlocked camera zone

Keeps track of players and enemies, it's used to figure out which enemies are in the unlocked region
and to attach a personal camera to the player, as well as disconnect it when needed.
Make sure to NOT include the outer ring of tiles you want to display
- see unlock_camera and lock_camera for more details

It's pretty much impossible to resize the detection area, would be a nice enhancement
"""

func _ready() -> void:
	add_to_group("entity_detect")

func _on_Area2D_body_entered(body: Entity) -> void:
	if body.TYPE == "PLAYER" && body.is_network_master():
		var col_shape = $CollisionShape2D.shape.extents
	
		# Make the camera 1 tile wider and higher than the detection range
		# This is to ensure smooth transitions when transitioning from locked to unlocked camera (and back)
		var limits = {
			"left": position.x - col_shape.x - 16,
			"top": position.y - col_shape.y - 16,
			"right": position.x + col_shape.x + 16,
			"bottom": position.y + col_shape.y + 16
		}
		
		body.camera.unlock_camera(limits)

func _on_Area2D_body_exited(body: Entity) -> void:
	if body.TYPE == "PLAYER" && body.is_network_master():
		body.camera.lock_camera()
