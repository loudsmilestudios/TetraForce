extends Camera2D

const SCREEN_SIZE = Vector2(256, 144)
const SCROLL_SPEED = 0.5

var target
var target_grid_pos = Vector2(0,0)
var last_target_grid_pos = Vector2(0,0)
var camera_rect = Rect2()

var current_lighting: String = ""

signal screen_change
signal screen_change_started
signal screen_change_completed
signal lighting_mode_changed

func _ready():
	set_process(false)

func initialize(node):
	target = node
	position = get_grid_pos(target.position) * SCREEN_SIZE
	$Tween.connect("tween_started", self, "screen_change_started")
	$Tween.connect("tween_completed", self, "screen_change_completed")
	current = true
	
	set_process(true)
	
	update_lighting(get_grid_pos(target.position))

func _process(delta):
	if target == null:
		return
	
	target_grid_pos = get_grid_pos(target.position)
	
	camera_rect = Rect2(position, SCREEN_SIZE)
	
	if $Tween.is_active():
		emit_signal("screen_change")
	
	if !$Tween.is_active() && !camera_rect.has_point(target.position):
		scroll_camera()
	
	last_target_grid_pos = target_grid_pos

func scroll_camera():
	$Tween.interpolate_property(self, "position", last_target_grid_pos * SCREEN_SIZE, target_grid_pos * SCREEN_SIZE, SCROLL_SPEED, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	
	update_lighting(target_grid_pos)
	
func update_lighting(target_grid_pos: Vector2):
	var grid_pos = get_grid_pos(target.position)
	var node_name = "room%s%s" % [grid_pos.x, grid_pos.y]
	
	var node = get_parent().get_node_or_null(node_name)
	
	if node == null:
		return
	
	var light_data = node.get_meta("light_data")
	
	if current_lighting == light_data:
		return
	
	var targetColor = Color(0, 0, 0, 1.0)
	var targetEnergy = 1
	var delay = 0.0
	
	if current_lighting == "dark":
		delay = 0.3
	
	if light_data == "dark":
		targetColor = Color(0, 0, 0, 1.0)
	elif light_data == "dusk":
		targetColor = Color(0.1, 0.0, 0.5, 1.0)
	elif light_data == "dawn":
		targetColor = Color(0.98, 0.482, 0.384, 1.0)
	else:
		targetColor = Color(1.0, 1.0, 1.0, 1.0)
		light_data = "day"
		targetEnergy = 0
			
	$ModulateTween.interpolate_property($CanvasModulate, "color", $CanvasModulate.color, targetColor, 0.2, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT, delay)
	$ModulateTween.start()
	
	current_lighting = light_data
			
	emit_signal("lighting_mode_changed", targetEnergy)
	

func get_grid_pos(pos):
	var x = floor(pos.x / SCREEN_SIZE.x)
	var y = floor(pos.y / SCREEN_SIZE.y)
	return Vector2(x,y)

func screen_change_started(object, nodepath):
	emit_signal("screen_change_started")

func screen_change_completed(object, nodepath):
	emit_signal("screen_change_completed")
