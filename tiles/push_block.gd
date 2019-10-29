extends KinematicBody2D

class_name PushBlock,"res://tiles/push_block.png"

onready var tween := $Tween
onready var ray := $RayCast2D

var push_acumulator = 0

func _process(delta):
	if push_acumulator>0:
		push_acumulator -= delta
	if push_acumulator < 0:
		push_acumulator == 0


func push(delta,from:Vector2):
	var relative_pos = (global_position - from).snapped(Vector2(16,16))
	ray.cast_to = relative_pos.normalized()*16
	push_acumulator = push_acumulator+2*delta
	if push_acumulator<1: return
	if tween.is_active(): return
	if ray.get_collider(): return
	# We need to take only player position and not how he move otherwize we can trick the block to move up!
	
	if abs(relative_pos.x) > abs(relative_pos.y):
		if relative_pos.x>0:
			tween_move(Vector2.RIGHT*16)
		else:
			tween_move(Vector2.LEFT*16)
	else:
		if relative_pos.y>0:
			tween_move(Vector2.DOWN*16)
		else:
			tween_move(Vector2.UP*16)

func tween_move(to:Vector2):
	push_acumulator = 0.5
	tween.interpolate_property(self,"position",position,position+to,1,Tween.TRANS_LINEAR,Tween.EASE_IN)
	tween.start()
