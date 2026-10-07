extends Control

var selected = 0

var skins = {
	"Chain": "res://entities/player/chain.png",
	"Knot": "res://entities/player/knot.png",
	"Key": "res://entities/player/key.png",
}

func _ready():
	global.connect("options_loaded", Callable(self, "update_options"))
	IdentityService.connect("identity_loaded", Callable(self, "on_identity_loaded"))
	update_skin(0)
	$back.connect("pressed", Callable(self, "update_skin").bind(-1))
	$forward.connect("pressed", Callable(self, "update_skin").bind(1))

func update_options():
	$preview.texture = load(global.options.player_data.skin)

func on_identity_loaded(id : Identity):

	if id.platform == "guest":
		$name.text = str(id.username)
		$name.editable = true
	else:
		$name.max_length = 0
		$name.text = "%s:%s" % [IdentityService.my_identity.platform, IdentityService.my_identity.display_name]
		$name.tooltip_text = "You can update your name on %s" % IdentityService.my_identity.platform
		$name.editable = false

func update_skin(i):
	selected = wrapi(selected + i, 0, skins.size())
	
	$preview.texture = load(skins.values()[selected])
	
	if skins.keys().has($name.text):
		$name.text = skins.keys()[selected]
		global.options.player_data.name = $name.text
	
	global.options.player_data.skin = skins.values()[selected]

func _on_name_text_changed(new_text):
	#global.options.player_data.name = new_text
	pass
