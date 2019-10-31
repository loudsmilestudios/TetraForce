extends Entity

export (float) var timer

var movetimer = 0

func _ready():
	var direction  = spritedir


func _physics_process(delta):
	var movetimer_length = timer
	if movetimer >= 0:
		movetimer -= 1
	else:
		use_item("res://items/arrow.tscn", "A")
		movetimer = movetimer_length
