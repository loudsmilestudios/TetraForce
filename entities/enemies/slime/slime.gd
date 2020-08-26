extends Enemy

var movetimer_length = 30
var movetimer = 0

export var color = "green"

func _ready():
	match color:
		"green":
			sprite.texture = preload("res://entities/enemies/slime/green.png")
			MAX_HEALTH = 0.5
			DAMAGE = 0.5
		"red":
			sprite.texture = preload("res://entities/enemies/slime/red.png")
			MAX_HEALTH = 1.0
			DAMAGE = 1
	health = MAX_HEALTH
	movedir = rand_direction()

func _physics_process(delta):
	if !network.is_map_host() || is_dead():
		return
	
	loop_movement()
	loop_spritedir()
	loop_damage()
	
	anim_switch("walk")
	
	if movetimer > 0:
		movetimer -= 1
	
	if movetimer == 10:
		movedir = Vector2.ZERO
	if movetimer == 0 || is_on_wall():
		movedir = rand_direction()
		movetimer = movetimer_length
