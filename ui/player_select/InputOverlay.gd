extends Control

signal submission(result)
signal close_without_submission

@export var button_text: String = "Submit"
@export var placeholder_text: String = ""

func _ready():
	self.connect("focus_entered", Callable(self, "on_focused"))
	
	$Button.connect("button_down", Callable(self, "submit"))
	$TextEdit.connect("text_submitted", Callable(self, "submit"))
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
