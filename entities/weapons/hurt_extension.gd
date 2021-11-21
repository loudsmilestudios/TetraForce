extends Weapon

export(bool) var active = false

func _ready():
	$Hitbox.connect("body_entered", self, "body_entered")
	
func body_entered(body):
	if !active:
		return
	if body is Entity && body != get_parent():
		damage(body)
