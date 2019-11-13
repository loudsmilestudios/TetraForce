extends Item

var shooter
var timer
var exploded
var blasted_walls
var fuse

puppet var puppet_pos = position

func start():
	shooter = get_parent()
	blasted_walls = []
	fuse = 2
	exploded = false
	TYPE = "TRAP"
	add_to_group("projectile")
	
	#Set damage to 0
	DAMAGE = 0
	$AnimationPlayer.play("default")
	#can't seem to get this working. 
	#Using the timer set up below as a workaround for now
	#$AnimationPlayer.connect("animation_finished",self,"_on_timeout")
	set_physics_process(true)
	$Hitbox.connect("body_entered", self, "body_entered")
	
	#set up positioning data
	position = shooter.position
	z_index = shooter.z_index + 1
	
	#move bomb from player object to world.
	shooter.remove_child(self)
	shooter.get_parent().add_child(self)
	
	#Set up timer
	timer = Timer.new()
	timer.connect("timeout", self, "_on_timeout")
	timer.set_wait_time( 2 )
	add_child(timer)
	timer.start()
		
func body_entered(body):
	#Add all blastable walls to an array for later.
	if body.has_method("blast"):
		if !exploded:
			blasted_walls.push_back(body)

func _on_timeout():
	timer.stop()
	exploded = true
	# We're exploding now, set the damage value.
	DAMAGE = 2
	
	# iterate over blasted walls and trigger the blast method
	for body in blasted_walls:
		if body.has_method("blast"):
			body.blast()
			
	#attach the explode animation
	var death_animation = preload("res://items/bomb_explode.tscn").instance()
	death_animation.global_position = global_position
	get_parent().add_child(death_animation)
	
	# hide the sprite
	$Sprite.visible = false
	
	#set a timer to delete the bomb in a half second. 
	var timer2 = Timer.new()
	timer2.connect("timeout", self, "delete")
	timer2.set_wait_time( 0.5 )
	add_child(timer2)
	timer2.start()
	
sync func delete():
	queue_free()
