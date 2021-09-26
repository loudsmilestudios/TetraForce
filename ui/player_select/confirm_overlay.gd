extends Control

signal submission(result)
signal close_without_submission

export(String) var confirm_text = "Yes"
export(String) var deny_text = "Cancel"
export(String) var message = "Are you sure?"

func _ready():
	set_message(message)
	$Confirm.text = confirm_text
	$Deny.text = deny_text
	
	self.connect("focus_entered", self, "on_focused")
	
	$Confirm.connect("button_down", self, "submit", [true])
	$Deny.connect("button_down", self, "submit", [false])

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
