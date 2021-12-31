extends Weapon

onready var anim = $AnimationPlayer

func start():
	$Hitbox.connect("body_entered", self, "body_entered")
	anim.play("deadcaptain_sword")
	
func body_entered(body):
	if body is Entity && body != get_parent():
		damage(body)
		
