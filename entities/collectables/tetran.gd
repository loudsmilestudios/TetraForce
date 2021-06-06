extends Collectable

enum TETRANS {WHITE = 1, ORANGE = 5, BLUE = 10, GREEN = 20, BLACK = 50, GOLD = 100}

export(TETRANS) var value = 5
# Called when the node enters the scene tree for the first time.

func _ready():
	var choice = randi() % 100
	if choice < 5:
		value = TETRANS.BLUE
	elif choice < 25:
		value = TETRANS.ORANGE
	else:
		value = TETRANS.WHITE
	$AnimationPlayer.play(str(value))

func _on_collect(body):
	global.ammo.tetrans += value
	if body.hud:
		body.hud.update_tetrans()
