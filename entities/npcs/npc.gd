extends KinematicBody2D

class_name NPC
onready var anim = $AnimationPlayer
var spritedir = "Down"

export var direction = "Down"
export var dialogue = ""
export var texture = "girl"

func _ready():
	$Sprite.texture = load(str("res://entities/npcs/", texture, ".png"))
	spritedir = direction
	add_to_group("nopush")
	add_to_group("interactable")
	anim_switch("idle")

func interact(node):
	spritedir = get_direction(node)
	anim_switch("idle")
	var dialogue_manager = preload("res://ui/dialogue/dialogue_manager.tscn").instance()
	node.add_child(dialogue_manager)
	node.state = "menu"
	dialogue_manager.file_name = dialogue
	dialogue_manager.Begin_Dialogue()
	yield(dialogue_manager, "finished")
	spritedir = direction
	anim_switch("idle")

func get_direction(entity):
	match entity.spritedir:
		"Down":
			return "Up"
		"Up":
			return "Down"
		"Left":
			return "Right"
		"Right":
			return "Left"

func anim_switch(a):
	var newanim: String = str(a, spritedir)
	if ["Left","Right"].has(spritedir):
		newanim = str(a, "Side")
	if anim.current_animation != newanim:
		anim.play(newanim)
	$Sprite.flip_h = spritedir == "Left"
