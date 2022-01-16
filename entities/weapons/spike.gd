extends Weapon

const SPEED = 250
var movedir = Vector2(0,0)
var shooter
var received_sync = false

func start():
	shooter = get_parent()
	$Hitbox.connect("body_entered", self, "body_entered")
	add_to_group("projectile")
	sfx.play("bow")
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
	
	get_parent().remove_child(self)
	shooter.get_parent().add_child(self)
	
	if !is_network_master():
		network.peer_call_id(get_network_master(), self, "request_arrow_sync", [network.pid])
	set_physics_process(true)

func request_arrow_sync(id):
	network.peer_call_id(id, self, "arrow_sync", [movedir, rotation_degrees])

func arrow_sync(dir, rot):
	movedir = dir
	rotation_degrees = rot
	received_sync = true

func _physics_process(delta):
	position += movedir * SPEED * delta

func body_entered(body):
	if !received_sync && !is_network_master() && body != shooter:
		queue_free()
	elif body is Entity && body != shooter:
		damage(body)
	elif body != shooter:
		delete()
		network.peer_call(self, "delete")





