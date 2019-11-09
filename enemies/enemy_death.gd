extends Node2D

func _ready() -> void:
	$AnimationPlayer.play("default")
	$AnimationPlayer.connect("animation_finished",self,"delete")
	sfx.play(preload("res://enemies/enemy_death.wav"))

func delete(a) -> void:
	queue_free()
