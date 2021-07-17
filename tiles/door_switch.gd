extends Area2D

var object
var pressed = false

onready var pushed = false setget set_pushed

func _ready():
	self.connect("area_entered", self, "on_pressed")
	self.connect("body_entered", self, "on_body_entered")
	self.connect("body_exited", self, "on_body_exit")
	set_physics_process(false)
	
func _physics_process(delta):
	if pressed == false:
		yield(get_tree().create_timer(0.5), "timeout")
		if get_overlapping_areas():
			set_pushed(true)
			set_physics_process(false)
		else:
			set_physics_process(false)

func on_pressed(area):
	object = area
	if pressed == false && area.name == "weight":
		set_physics_process(true)
		
func on_body_entered(body):
	if pressed == true:
		return
	if pressed == false:
		set_physics_process(true)
	if $AnimationPlayer.current_animation == "Up":
		global.player.sprite.offset.y = global.player.sprite.offset.y - 3
		
func on_body_exit(body):
	if pressed == true:
		return
	global.player.sprite.offset.y = 0
	
func set_pushed(value):
	if pushed:
		$AnimationPlayer.play("Down")
		global.player.sprite.offset.y = 0
		if pressed == false:
			pressed = true
	else:
		$AnimationPlayer.play("Up")
	pushed = value
