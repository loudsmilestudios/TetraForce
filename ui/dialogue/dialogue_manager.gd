extends CanvasLayer

#---File---#
var file_name: String = "dialogue_1" # File Name Imported from Tiled
var nodes # contains all the nodes of the current dialogue

#----DATA (from file)-----#
var curent_node_id = -1 # handles the current node we are traversing Note: -1 exits the dialogue
var curent_node_name # name of the speaker 
var curent_node_text # dialogue text
var curent_node_next_id # connect to the next node Note: ignored if curent_node_choices has things inside
var curent_node_choices = [] # If you want more than one possible answear, you should fill this up

var force = false # force start the dialogue
var random = false # Start from random node

var text_finished = false


#------UI--------#
@onready var choiceBox = $DialogueUI/ChoiceBox
@onready var dialogueText = $DialogueUI/DialogueText
@onready var dialoguePanel = $DialogueUI #Less rewritting if you want to move the script to another object
@onready var dialogueName = $DialogueUI/DialogueName
var tween: Tween
@onready var dialogueButtons = [$DialogueUI/ChoiceBox/Button1,$DialogueUI/ChoiceBox/Button2]
var button_connections = {}

signal finished

func _input(event):
	if tween and tween.is_valid():
		tween.set_speed_scale(2.0 if Input.is_action_pressed("B") else 1.0)
	if Input.is_action_just_pressed("UP"):
		dialogueButtons[0].grab_focus()
	if Input.is_action_just_pressed("DOWN"):
		dialogueButtons[1].grab_focus()
	
#-----Load JSON File-----#
func LoadFile(fname):
	file_name = fname
	var path = "res://dialogue/" + file_name + ".json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var json_result = JSON.parse_string(file.get_as_text())
		if not json_result is Dictionary:
			print("Dialogue: Invalid JSON")
			return
		force = bool(json_result["Force"])
		random = bool(json_result["Random"])
		curent_node_id = 0
		nodes = json_result["Nodes"]
	else:
		print("Dialogue: File Open Error")
	if force:
		StartDialogue()
	
#-----Traversing Graph-----#
func StartDialogue():
	if nodes:
		if random:
			var temp = []
			for x in nodes:
				temp.append(x["id"])
			curent_node_id = temp[randi()%temp.size()]
		else:
			curent_node_id = 0
		HandleNode()
		
	else:
		print("Dialogue: Could not Find Nodes")

func EndDialogue():
		curent_node_id = -1

func NextNode(id):
	curent_node_id = id
	HandleNode()

#----Handle Current Node-----#
func HandleNode():
	if curent_node_id < 0 :
		EndDialogue()
	else:
		if !GrabNode(curent_node_id):
			EndDialogue()
	UpdateUI()
	
func GrabNode(id):
	for node in nodes:
		if int(node["id"]) == id:
			curent_node_name = node["name"]
			curent_node_text = node["text"]
			curent_node_next_id = int(node["next_id"])
			curent_node_choices = node["choices"]
			return true
	return false

#----Update UI-----#
func UpdateUI():
	choiceBox.hide()
	if curent_node_id >= 0:
		Dialogue_Anim()
		dialoguePanel.show()
		for x in dialogueButtons:
			x.hide()
			if button_connections.has(x):
				var callback: Callable = button_connections[x]
				if x.pressed.is_connected(callback):
					x.pressed.disconnect(callback)
		button_connections.clear()
			
		dialogueName.text = curent_node_name
		dialogueText.text = curent_node_text
		if curent_node_choices.size() > 0:
			choiceBox.position.y = -33
			for x in min(curent_node_choices.size(), dialogueButtons.size()):
				dialogueButtons[x].text = curent_node_choices[x]["text"]
				
				var callback = Callable(self, "_on_Button_Pressed").bind(curent_node_choices[x]["next_id"])
				dialogueButtons[x].pressed.connect(callback)
				button_connections[dialogueButtons[x]] = callback
				
				dialogueButtons[x].show()
				dialogueButtons[0].grab_focus()
				
		else:
			dialogueButtons[0].text = "Continue"
			choiceBox.position.y = -33
			dialogueButtons[0].show()
			var callback = Callable(self, "_on_Button_Pressed").bind(curent_node_next_id)
			dialogueButtons[0].pressed.connect(callback)
			button_connections[dialogueButtons[0]] = callback

	else:
		get_parent().action_cooldown = 10
		get_parent().state = "default"
		dialogueText.visible_ratio = 0
		emit_signal("finished")
		queue_free()
		

#-----Text Animation-----#
func Dialogue_Anim():
	text_finished = false
	$"DialogueUI/next-indicator".hide()
	var line_speed = (curent_node_text.length() * 0.02)
	if tween and tween.is_valid():
		tween.kill()
	dialogueText.visible_ratio = 0.0
	tween = create_tween().set_trans(Tween.TRANS_LINEAR)
	tween.tween_property(dialogueText, "visible_ratio", 1.0, line_speed)
	tween.finished.connect(_on_text_tween_finished)
	sfx.play("dialogue")

#-----On Button Pressed-----#
func _on_Button_Pressed(id):
	sfx.play("item_select")
	NextNode(id)

#-----Initiate Dialogue-----#
func Begin_Dialogue():
	choiceBox.position.y = -33
	LoadFile(file_name)
	StartDialogue()

#-----Prompt Once Text Complete-----#
func _on_text_tween_finished():
	text_finished = true
	$"DialogueUI/next-indicator".show()
	choiceBox.show()
	dialogueButtons[0].grab_focus()
