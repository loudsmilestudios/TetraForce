extends Area2D

class_name Collectable

var item_position = []

@export var timer_till_self_destruct: float
@export var time_till_flashing: float = 5 # Is the time till the collectable starts flashing, in seconds
@export var sound: String = "tetran"

const TOTAL_FLASH_COUNT = 15; # Total amount of flashes 
const FLASH_TIME_VISIBLE = .1; # Time when collectables are invisible while flashing
const FLASH_TIME_NOT_VISIBLE = .1; # Time when collectables are visible while flashing

var flash_count = 0; # Current counter of flashes

func _ready():
	initialize_collectable()

func initialize_collectable(create_network_object = true):
	collision_mask = 1 << 1
	self.connect("body_entered", Callable(self, "_collect"))
	add_to_group("collectable") #Group to find node
	var timer = Timer.new()
	add_child(timer)
	timer.wait_time = time_till_flashing
	
	if network.is_map_host():
		timer.connect("timeout", Callable(self, "_flash"))
		timer.name = "Timer"
		if time_till_flashing > 0 != is_in_group("key_spawn"): 
			timer.start()
			
	if create_network_object:
		var network_object = preload("res://engine/network_object.tscn").instantiate()
		add_child(network_object)
		network_object.enter_properties = {"position":position}
		network_object.update_properties = {"position":position}
		network_object.require_map_host = true
		network_object.sync_creation = true
	#print(network_object.enter_properties)
	
	$CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(0.75).timeout
	if is_instance_valid($CollisionShape2D):
		$CollisionShape2D.set_deferred("disabled", false)

func _flash():
	flash_count+=1
	if(flash_count == TOTAL_FLASH_COUNT * 2):
		network.peer_call(self, "queue_free")
		queue_free()
		network.states.collectables.erase(self)

	if($Sprite2D.visible):
		$Timer.wait_time = FLASH_TIME_NOT_VISIBLE
	else:
		$Timer.wait_time = FLASH_TIME_VISIBLE
	network.peer_call(self, "_start_flash", [!$Sprite2D.visible])
	_start_flash(!$Sprite2D.visible)

	$Timer.start()

func _start_flash(is_visible):
	$Sprite2D.visible = is_visible
	
# Function to be overrided by extended script, queue_free is not needed
func _on_collect(body):
	pass

# Calls inherited _on_collect function, and will (with fornclake's edit) be freed on every client
func _collect(body: Node2D):
	if body is Entity && body.TYPE == "PLAYER": 
		_on_collect(body) # Collect Function
		sfx.play(sound)
		# Deletion Code with network syncing goes here:
		queue_free()
		network.states.collectables.erase(self)
