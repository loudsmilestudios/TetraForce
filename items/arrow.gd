extends Item

const SPEED = 150
var movedir = Vector2(0,0)
var shooter

func start():
	shooter = get_parent()
	add_to_group("projectile")
	z_index = shooter.z_index - 1
	get_parent().remove_child(self)
	shooter.get_parent().add_child(self)
	position = shooter.position
	
	match shooter.spritedir:
		"Right":
			movedir = Vector2.RIGHT
			rotation_degrees = 0
		"Down":
			movedir = Vector2.DOWN
			rotation_degrees = 90
		"Left":
			movedir = Vector2.LEFT
			rotation_degrees = 180
		"Up":
			movedir = Vector2.UP
			rotation_degrees = 270
	
	
	if is_network_master():
		var network_object = preload("res://engine/network_object.tscn").instance()
		add_child(network_object)
		network_object.require_map_host = false
		network_object.update_properties = {"position":position}
		
		$Hitbox.connect("body_entered", self, "body_entered")
		set_physics_process(true)

func _physics_process(delta):
	position += movedir * SPEED * delta

func body_entered(body):
	if body is Entity && body != shooter:
		damage(body)
	elif body != shooter:
		delete()
		network.peer_call(self, "delete")





