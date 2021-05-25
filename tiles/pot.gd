extends StaticBody2D

export var color = "blue"

onready var animation = $AnimationPlayer

var spawn = false

func _ready():
	add_to_group("bombable")
	match color:
		"blue":
			$Sprite.texture = preload("res://tiles/post_smash_blue.png")
		"red":
			$Sprite.texture = preload("res://tiles/post_smash_red.png")
		"yellow":
			$Sprite.texture = preload("res://tiles/post_smash_yellow.png")

func cut(hitbox):
	if global.player.spritedir != "Up":
		self.z_index = 500
	var pos = self.position
	animation.play("break")
	sfx.play("pot")
	if spawn == false:
		network.current_map.spawn_collectable("tetran", pos, 6)
		spawn = true
		
func bombed():
	var pos = self.position
	animation.play("break")
	sfx.play("pot")
	if spawn == false:
		network.current_map.spawn_collectable("tetran", pos, 6)
		spawn = true
