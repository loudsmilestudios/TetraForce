extends Entity

export (float) var timer
export (String) var direction
var movetimer = 0

func _init():
	TYPE = "TRAP"

func _ready():
	spritedir = direction
	if spritedir == "Left":
		$AnimatedSprite.set_animation(spritedir.to_lower())
	if spritedir == "Up":
		$AnimatedSprite.set_animation(spritedir.to_lower())
	if spritedir == "Right":
		$AnimatedSprite.set_animation(spritedir.to_lower())
	if spritedir == "Down":
		$AnimatedSprite.set_animation(spritedir.to_lower())
func _physics_process(delta):
	if movetimer >= 0:
		movetimer -= 1
	else:
		use_item("res://items/arrow.tscn", "A")
		movetimer = timer
