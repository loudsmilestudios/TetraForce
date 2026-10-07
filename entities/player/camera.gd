extends Camera2D

var target
var current_rect
var scroll_tween: Tween
var screen_size = Vector2(256,144)

const SCROLL_DURATION = 0.5

signal reset_limit

func _ready():
	set_process(false)
	
func _physics_process(_delta):
	if is_instance_valid(global.player):
		global.player.get_node("PointLight2D").enabled = global.items.has("Lantern") #Moved so it updates while your in a dark room

func initialize(node):
	target = node
	enabled = true
	
func scroll_screen(rect : Rect2):
	if rect == current_rect:
		return
	current_rect = rect
	
	target.set_physics_process(false) # yes i know i should use signals
	set_process(false)
	
	var scroll_from = get_screen_center_position()
	
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
	
	
	if scroll_tween and scroll_tween.is_valid():
		scroll_tween.kill()
	scroll_tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
	scroll_tween.tween_property(self, "position", scroll_to, SCROLL_DURATION).from(scroll_from)
	await scroll_tween.finished
	
	set_limits(rect)
	position_smoothing_enabled = true
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
		target.get_node("PointLight2D").enabled = false
		for light in get_tree().get_nodes_in_group("light_halo"):
			light.enabled = false
			
func on_screen_shake():
	$AnimationPlayer.play("screenshake")
