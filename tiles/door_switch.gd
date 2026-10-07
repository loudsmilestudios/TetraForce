extends Area2D

@export var requires_weight: bool = false

var player
var pressed = false
var press_pending = false
var timer: Timer

@onready var pushed = false: set = set_pushed

signal on_button_pressed
signal no_weight

func _ready():
	timer = Timer.new()
	self.connect("area_entered", Callable(self, "on_pressed"))
	self.connect("area_exited", Callable(self, "on_released"))
	self.connect("body_entered", Callable(self, "on_body_entered"))
	self.connect("body_exited", Callable(self, "on_body_exit"))
	set_physics_process(false)
	timer.connect("timeout", Callable(self, "check_door"))
	timer.set_wait_time(1)
	add_child(timer)
	timer.start()
	
func _physics_process(delta):
	if pressed || press_pending:
		return
	press_pending = true
	await get_tree().create_timer(0.5).timeout
	press_pending = false
	if get_overlapping_areas() || get_overlapping_bodies():
		open()
	else:
		check_door()
			
func check_door():
	set_physics_process(false)
	if !get_overlapping_areas() && requires_weight:
		emit_signal("no_weight")
		
func open():
	set_pushed(true)
	network.peer_call(self, "set_pushed", [true])
	emit_signal("on_button_pressed")
	set_physics_process(false)
	if is_instance_valid(player):
		player.sprite.offset.y = 0

func on_pressed(area):
	if pressed == false && area.name == "weight":
		set_physics_process(true)
		
func on_released(area):
	if requires_weight && !get_overlapping_areas():
		set_pushed(false)
		network.peer_call(self, "set_pushed", [false])
		emit_signal("no_weight")
		
func on_body_entered(body):
	if not body is Entity:
		return
	player = body
	if pressed == false:
		set_physics_process(true)
	if $AnimationPlayer.current_animation == "Up":
		body.sprite.offset.y = body.sprite.offset.y - 3
		
func on_body_exit(body):
	if not body is Entity:
		return
	if pressed == true:
		return
	body.sprite.offset.y = 0
	if requires_weight && !get_overlapping_areas():
		set_pushed(false)
		network.peer_call(self, "set_pushed", [false])
		emit_signal("no_weight")
	
func set_pushed(value):
	pushed = value
	if pushed:
		$AnimationPlayer.play("Down")
	else:
		$AnimationPlayer.play("Up")
	
