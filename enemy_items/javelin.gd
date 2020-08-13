extends Item

const SPEED = 150
var movedir = Vector2(0,0)
var shooter
var received_sync = false

const KNOCKBACK = 5

func _init():
	DAMAGE = .5

func start():
	shooter = get_parent()
	$Hitbox.connect("body_entered", self, "body_entered")
	add_to_group("projectile")
	z_index = shooter.z_index - 1
	position = shooter.position

	movedir = input
	rotation_degrees = rad2deg(movedir.angle())
	
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
	if !received_sync && is_network_master() && body != shooter:
		if body is Entity:
			body.damage(DAMAGE, KNOCKBACK * movedir)
		else:
			queue_free()
	elif body is Entity && body != shooter:
		body.damage(DAMAGE, KNOCKBACK * movedir)
	elif body != shooter:
		delete()
		network.peer_call(self, "delete")




