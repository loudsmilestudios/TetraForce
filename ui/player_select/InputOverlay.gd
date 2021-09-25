extends Control

signal submission(result)
signal close_without_submission

export(String) var button_text = "Submit"
export(String) var placeholder_text = ""

func _ready():
	self.connect("focus_entered", self, "on_focused")
	
	$Button.connect("button_down", self, "submit")
	$TextEdit.connect("text_entered", self, "submit")
	$Button.text = button_text
	$TextEdit.placeholder_text = placeholder_text

func submit(val = null):
	emit_signal("submission", $TextEdit.text)
	hide()

func on_focused():
	$TextEdit.grab_focus()

func open():
	self.show()
	self.on_focused()

func close():
	self.hide()
	emit_signal("close_without_submission")
