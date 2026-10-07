extends Control

signal submission(result)
signal close_without_submission

@export var confirm_text: String = "Yes"
@export var deny_text: String = "Cancel"
@export var message: String = "Are you sure?"

func _ready():
	set_message(message)
	$Confirm.text = confirm_text
	$Deny.text = deny_text
	
	self.connect("focus_entered", Callable(self, "on_focused"))
	
	$Confirm.connect("button_down", Callable(self, "submit").bind(true))
	$Deny.connect("button_down", Callable(self, "submit").bind(false))

func set_message(msg):
	message = msg
	$Message.text = msg

func submit(input_result = null):
	emit_signal("submission", input_result)
	hide()

func on_focused():
	$Confirm.grab_focus()

func open():
	self.show()
	self.on_focused()

func close():
	self.hide()
	emit_signal("close_without_submission")
