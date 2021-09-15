extends Area2D

class_name Collectable

var item_position = []

export(float) var timer_till_self_destruct
export(float) var time_till_flashing = 5 # Is the time till the collectable starts flashing, in seconds
export(String) var sound = "tetran"

const TOTAL_FLASH_COUNT = 15; # Total amount of flashes 
const FLASH_TIME_VISIBLE = .1; # Time when collectables are invisible while flashing
const FLASH_TIME_NOT_VISIBLE = .1; # Time when collectables are visible while flashing

var flash_count = 0; # Current counter of flashes

func _ready():
	self.connect("body_entered", self, "_collect")
	add_to_group("collectable") #Group to find node
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = time_till_flashing
	
	if network.is_map_host():
		timer.connect("timeout", self, "_flash")
		timer.name = "Timer"
		if time_till_flashing > 0 != is_in_group("key_spawn"): 
			timer.start()
			
	var network_object = preload("res://engine/network_object.tscn").instance()
	add_child(network_object)
	network_object.enter_properties = {"position":position}
	network_object.update_properties = {"position":position}
	network_object.require_map_host = true
	network_object.sync_creation = true
	#print(network_object.enter_properties)
	
	$CollisionShape2D.disabled = true
	yield(get_tree().create_timer(0.75), "timeout")
	$CollisionShape2D.disabled = false

func _flash():
	flash_count+=1
	if(flash_count == TOTAL_FLASH_COUNT * 2):
		network.peer_call(self, "queue_free")
		queue_free()
		network.states.collectables.erase(self)

	if($Sprite.visible):
		$Timer.wait_time = FLASH_TIME_NOT_VISIBLE
	else:
		$Timer.wait_time = FLASH_TIME_VISIBLE
	network.peer_call(self, "_start_flash", [!$Sprite.visible])
	_start_flash(!$Sprite.visible)

	$Timer.start()

func _start_flash(is_visible):
	$Sprite.visible = is_visible
	
# Function to be overrided by extended script, queue_free is not needed
func _on_collect(body):
	print($gap_delay.time_left)

# Calls inherited _on_collect function, and will (with fornclake's edit) be freed on every client
func _collect(body: Node2D):
	if body is Entity && body.TYPE == "PLAYER": 
		_on_collect(body) # Collect Function
		sfx.play(sound)
		# Deletion Code with network syncing goes here:
		queue_free()
		network.states.collectables.erase(self)
