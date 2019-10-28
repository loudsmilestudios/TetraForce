extends Item

const SPEED = 150
var movedir = Vector2(0,0)

var shooter

puppet var puppet_pos = position

func start():
	shooter = get_parent()
	$Hitbox.connect("body_entered", self, "body_entered")
	add_to_group("projectile")
	z_index = shooter.z_index - 1
	
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
	
	position = shooter.position
	
	set_physics_process(true)

func _physics_process(delta):
	position += movedir * SPEED * delta

func body_entered(body):
	if body.get("TYPE") != TYPE:
		delete()

sync func delete():
	queue_free()
