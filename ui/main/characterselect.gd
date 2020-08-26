extends Panel

var selected = 0

var skins = {
	"Chain": "res://entities/player/chain.png",
	"Knot": "res://entities/player/knot.png",
	"Key": "res://entities/player/key.png",
}

func _ready():
	global.connect("options_loaded", self, "update_options")
	update_skin(0)
	$back.connect("pressed", self, "update_skin", [-1])
	$forward.connect("pressed", self, "update_skin", [1])

func update_options():
	$name.text = global.options.player_data.name
	$preview.texture = load(global.options.player_data.skin)

func update_skin(i):
	selected = wrapi(selected + i, 0, skins.size())
	
	$preview.texture = load(skins.values()[selected])
	
	if skins.keys().has($name.text):
		$name.text = skins.keys()[selected]
		global.options.player_data.name = $name.text
	
	global.options.player_data.skin = skins.values()[selected]

func _on_name_text_changed(new_text):
	global.options.player_data.name = new_text
