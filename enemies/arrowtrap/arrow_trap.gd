extends Entity

export (float) var timer
export (String) var direction
var shoottimer = 0

func _init():
	TYPE = "TRAP"

func _ready():
	spritedir = direction
	if ["Left", "Up", "Right", "Down"].has(spritedir):
		$AnimatedSprite.set_animation(spritedir.to_lower())
	hitbox.queue_free()

func _physics_process(delta):
	if !is_scene_owner():
		return
	
	if shoottimer >= 0:
		shoottimer -= 1
	else:
		use_item("res://items/arrow.tscn", "A")
		for peer in network.map_peers:
			rpc_id(peer, "use_item", "res://items/arrow.tscn", "A")
		shoottimer = timer
