extends Panel

var selected = 0

var options = {
	"Chain": "res://player/player.png",
	"Knot": "res://player/knot.png",
	"Key": "res://player/key.png",
}

func _ready():
	update_skin(0)
	$back.connect("pressed", self, "update_skin", [-1])
	$forward.connect("pressed", self, "update_skin", [1])

func update_skin(i):
	selected = wrapi(selected + i, 0, options.size())
	
	$preview.texture = load(options.values()[selected])
	
	if options.keys().has($name.text):
		$name.text = options.keys()[selected]
	
	network.my_player_data.skin = options.values()[selected]

func _on_name_text_changed(new_text):
	network.my_player_data.name = new_text
