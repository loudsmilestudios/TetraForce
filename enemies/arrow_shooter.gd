extends Entity

export (float) var timer
export (String) var direction
var movetimer = 0

func _ready():
	spritedir = direction

func _physics_process(delta):
	if movetimer >= 0:
		movetimer -= 1
	else:
		
		use_item("res://items/arrow.tscn", "A")
		movetimer = timer
