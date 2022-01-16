class_name BossOverlay
extends Control

onready var bossbar = $Bossbar
onready var animation_player = $AnimationPlayer

func _ready():
	self.show()
	bossbar.hide()

func show_boss_bar():
	animation_player.play("show_bossbar")

func hide_boss_bar():
	animation_player.play("hide_bossbar")

func set_max_boss_hp(max_hp : float):
	bossbar.max_value = max_hp

func set_current_boss_hp(current_hp : float):
	bossbar.value = current_hp
