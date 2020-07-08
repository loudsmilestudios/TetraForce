extends Camera2D

const SCREEN_SIZE = Vector2(256, 144)
const SCROLL_SPEED = 0.5

var target
var target_grid_pos = Vector2(0,0)
var last_target_grid_pos = Vector2(0,0)
var camera_rect = Rect2()

signal screen_change
signal screen_change_started
signal screen_change_completed

func _ready():
	set_process(false)

func initialize(node):
	target = node
	position = get_grid_pos(target.position) * SCREEN_SIZE
	
	$Tween.connect("tween_started", self, "screen_change_started")
	$Tween.connect("tween_completed", self, "screen_change_completed")
	
	set_process(true)
	
	current = true

func _process(_delta):
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

func get_grid_pos(pos):
	var x: float = floor(pos.x / SCREEN_SIZE.x)
	var y: float = floor(pos.y / SCREEN_SIZE.y)
	return Vector2(x,y)

func screen_change_started(_object, _nodepath):
	emit_signal("screen_change_started")

func screen_change_completed(_object, _nodepath):
	emit_signal("screen_change_completed")
