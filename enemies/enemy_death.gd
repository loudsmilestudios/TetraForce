extends Node2D

func _ready():
	$AnimationPlayer.play("default")
	$AnimationPlayer.connect("animation_finished",self,"delete")
	sfx.play(preload("res://enemies/enemy_death.wav"))

func delete(a):
	queue_free()
