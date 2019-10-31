extends Entity
#First two are used to get input from the object placement screen, to see the delay between shots and which direction it shoots in.
export (float) var timer
export (String) var direction
#This is the timer that gets reset to timer.
var movetimer = 0

func _ready():
	#tells the arrow which direction. This should be made automated, but I dont know how to do that
	spritedir = direction

func _physics_process(delta):
	#It continuely is subtracted by 1
	if movetimer >= 0:
		movetimer -= 1
	#when it hits 0, it shoots, then resets itself
	else:
	
		use_item("res://items/arrow.tscn", "A")
		movetimer = timer
