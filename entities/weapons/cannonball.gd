extends Weapon

const SPEED = 125
var movedir = Vector2(0,0)
var shooter
var received_sync = false

func start():
	shooter = get_parent()
	$Hitbox.connect("body_entered", self, "body_entered")
	add_to_group("projectile")
	sfx.play("bow")
	z_index = shooter.z_index - 1
	position = shooter.position
	
	match shooter.spritedir:
		"Right":
			movedir = Vector2.RIGHT
			#position.y = position.y + 13
			#position.y = position.y - 2
		"Down":
			movedir = Vector2.DOWN
			position.y = position.y + 12
		"Left":
			movedir = Vector2.LEFT
			position.x = position.x - 13
			position.y = position.y - 2
		"Up":
			movedir = Vector2.UP
			position.y = position.y - 10
	
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
	if body.is_in_group("cannon"):
		body.on_explosion()
		delete()
		network.peer_call(self, "delete")
	elif !received_sync && !is_network_master() && body != shooter:
		queue_free()
	elif body is Entity && body != shooter:
		damage(body)
	elif body != shooter && !body.is_in_group("cannon"):
		delete()
		network.peer_call(self, "delete")
		shooter.fired = false
		shooter.add_to_group("interactable")
		network.peer_call(shooter, "add_to_group", ["interactable"])
	
