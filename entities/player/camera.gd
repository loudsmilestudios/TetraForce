extends Camera2D

var target
var current_rect
var screen_size = Vector2(256,144)

const SCROLL_DURATION = 0.5

signal reset_limit

func _ready():
	set_process(false)
	
func _physics_process(delta):
	global.player.get_node("Light2D").enabled = global.items.has("Lantern") #Moved so it updates while your in a dark room

func initialize(node):
	target = node
	current = true
	
func scroll_screen(rect : Rect2):
	if rect == current_rect:
		return
	current_rect = rect
	
	target.set_physics_process(false) # yes i know i should use signals
	set_process(false)
	
	var scroll_from = get_camera_screen_center()
	
	unlimit() # remove the current camera limits (can't have limits while scrolling)
	position = scroll_from
	
	# where we're scrolling to. it's the first position in the next zone that
	# is at least halfway through the screen size away from the edge.
	# basically fake limits code just used to get where the camera /will/ be
	var scroll_to = target.position
	var scroll_to_min = current_rect.position + screen_size / 2
	var scroll_to_max = current_rect.position + current_rect.size - screen_size / 2
	scroll_to.x = clamp(scroll_to.x, scroll_to_min.x + 16, scroll_to_max.x)
	scroll_to.y = clamp(scroll_to.y, scroll_to_min.y + 16, scroll_to_max.y)
	
	
	$Tween.interpolate_property(self, "position", scroll_from, scroll_to, SCROLL_DURATION, Tween.TRANS_LINEAR, Tween.EASE_IN_OUT)
	$Tween.start()
	yield($Tween, "tween_all_completed")
	
	set_limits(rect)
	smoothing_enabled = true
	target.set_physics_process(true)
	set_process(true)

func unlimit():
	limit_left = -1000000
	limit_right = 1000000
	limit_top = -1000000
	limit_bottom = 1000000

func set_limits(rect : Rect2):
	limit_left = int(rect.position.x)
	limit_right = int(rect.position.x + rect.size.x + 16)
	limit_top = int(rect.position.y)
	limit_bottom = int(rect.position.y + rect.size.y + 16)

func _process(_delta):
	if target == null:
		return
	position = target.position

func set_light(mode):
	if mode == "dark":
		$CanvasModulate.color = Color(0, 0, 0, 1.0)
	else:
		$CanvasModulate.color = Color(1.0, 1.0, 1.0, 1.0)
		target.get_node("Light2D").enabled = false
		for light in get_tree().get_nodes_in_group("light_halo"):
			light.enabled = false
			
func on_screen_shake():
	$AnimationPlayer.play("screenshake")
