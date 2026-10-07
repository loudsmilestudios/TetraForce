extends AnimationPlayer

func _ready():
	play("default")
	global.connect("save", Callable(self, "on_save"))

func on_save():
	if is_playing():
		stop()
	play("fade_out")
