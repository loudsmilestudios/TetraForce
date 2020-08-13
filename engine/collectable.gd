extends Area2D

class_name collectable

export(float) var timer_till_self_destruct
export(float) var time_till_flashing = 3 # Is the time till the collectable starts flashing, in seconds

const TOTAL_FLASH_COUNT = 5;
const FLASH_TIME_VISIBLE = .5;
const FLASH_TIME_NOT_VISIBLE = .3;
var flash_count = 0;



func _ready():
	self.connect("body_entered", self, "_collect")
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = time_till_flashing
	
	timer.connect("timeout", self, "_flash")
	timer.name = "Timer"
	if time_till_flashing > 0: timer.start()
	timer.one_shot = true

func _flash():
	flash_count+=1
	if(flash_count == TOTAL_FLASH_COUNT * 2):
		queue_free()

	if($Sprite.visible):
		$Timer.wait_time = FLASH_TIME_NOT_VISIBLE
	if(!$Sprite.visible):
		$Timer.wait_time = FLASH_TIME_VISIBLE
	$Sprite.visible = !$Sprite.visible

	$Timer.start()

	
# Function to be overrided by extended script, queue_free is not needed
func _on_collect():
	print($gap_delay.time_left)

# Calls inherited _on_collect function, and will (with fornclake's edit) be freed on every client
func _collect(body: Node2D):
	
	_on_collect() # Collect Function
	# Deletion Code with network syncing goes here:
	queue_free()
