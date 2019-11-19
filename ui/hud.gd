extends CanvasLayer

var player

const HEART_ROW_SIZE: int = 8
const HEART_SIZE: int = 8

onready var hearts := $Hearts


func initialize() -> void:
	player = global.player
	player.connect("health_changed", self, "update_hearts")
	
	for i in player.MAX_HEALTH:
		var newheart = Sprite.new()
		newheart.texture = hearts.texture
		newheart.hframes = hearts.hframes
		hearts.add_child(newheart)
		update_hearts()

func update_hearts() -> void:
	for heart in hearts.get_children():
		var index: int = heart.get_index()
		
		var x: float = (index % HEART_ROW_SIZE) * HEART_SIZE
		var y: float = (index / HEART_ROW_SIZE) * HEART_SIZE
		
		heart.position = Vector2(x,y)
		
		var lastheart: int = floor(player.health)
		if index > lastheart:
			heart.frame = 0
		if index == lastheart:
			heart.frame = (player.health - lastheart) * 4
		if index < lastheart:
			heart.frame = 4
