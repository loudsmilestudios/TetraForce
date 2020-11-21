extends Camera2D

var target
var current_rect

const SCROLL_DURATION = 0.5

func _ready():
	set_process(false)

func initialize(node):
	target = node
	current = true

func scroll_screen(rect : Rect2):
	if rect == current_rect:
		return
	current_rect = rect
	
	target.set_physics_process(false) # yes i know i should use signals
	set_process(false)
	smoothing_enabled = false
	
	var current_center = get_camera_screen_center()
	
	unlimit()
	position = current_center
	var new_center = get_new_center(rect)
	
	$Tween.interpolate_property(self, "position", current_center, new_center, SCROLL_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	
	set_limits(rect)
	
	smoothing_enabled = true
	target.set_physics_process(true)
	set_process(true)

func get_new_center(rect):
	var new_center = target.position
	new_center.x = clamp(new_center.x, rect.position.x + 128, rect.position.x + rect.size.x - 128 + 16)
	new_center.y = clamp(new_center.y, rect.position.y + 72, rect.position.y + rect.size.y - 72 + 16)
	return new_center

func unlimit():
	limit_left = -1000000
	limit_right = 1000000
	limit_top = -1000000
	limit_bottom = 1000000

func set_limits(rect):
	limit_left = rect.position.x
	limit_right = rect.position.x + rect.size.x + 16
	limit_top = rect.position.y
	limit_bottom = rect.position.y + rect.size.y + 16

func _process(_delta):
	if target == null:
		return
	position = target.position

func set_light(mode):
	if mode == "dark":
		$CanvasModulate.color = Color(0, 0, 0, 1.0)
		target.get_node("Light2D").enabled = global.items.has("Lantern")
	else:
		$CanvasModulate.color = Color(1.0, 1.0, 1.0, 1.0)
		target.get_node("Light2D").enabled = false
