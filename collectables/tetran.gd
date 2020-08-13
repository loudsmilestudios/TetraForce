extends collectable

enum TETRANS {WHITE = 1, ORANGE = 5, BLUE = 10, GREEN = 20, BLACK = 50, GOLD = 100}

export(TETRANS) var value = 5
# Called when the node enters the scene tree for the first time.

func _ready():
	$AnimationPlayer.play(str(value))

func _on_collect():
	pass

