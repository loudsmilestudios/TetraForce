extends CanvasLayer

var text = "Bees range in size from tiny stingless bee species whose workers are less than 2 millimetres (0.08 in) long, to Megachile pluto, the largest species of leafcutter bee, whose females can attain a length of 39 millimetres (1.54 in). The most common bees in the Northern Hemisphere are the Halictidae, or sweat bees, but they are small and often mistaken for wasps or flies. Vertebrate predators of bees include birds such as be... END"

const LINE_LENGTH = 38
const TEXT_SPEED = 0.02

var lines = []

signal line_end
signal advance_text
signal finished

func _ready():
	process_string(text)
	var line = 0
	while line < lines.size():
		write_line(line)
		yield(self, "line_end")
		$Text.newline()
		line += 1
		
		if line < lines.size():
			write_line(line)
			yield(self, "line_end")
			line += 1
		
		yield(self, "advance_text")
		sfx.play(preload("res://ui/dialog_line.wav"), 15)
		$Text.newline()
	emit_signal("finished")
	queue_free()

func process_string(s):
	if s.length() > LINE_LENGTH:
		var character = LINE_LENGTH
		while s[character] != " " && character > 1:
			character -= 1
		lines.append(s.left(character))
		text = text.right(character + 1)
		
		if text.length() > LINE_LENGTH:
			process_string(text)
		else:
			lines.append(text)
	else:
		lines.append(text)

func write_line(l):
	var line_text = lines[l]
	for character in lines[l]:
		$Text.text += character
		sfx.play(preload("res://ui/dialog_character.wav"), 15)
		var speed = TEXT_SPEED
		if Input.is_action_pressed(controller.B):
			speed = TEXT_SPEED / 2
		yield(get_tree().create_timer(speed), "timeout")
	emit_signal("line_end")

func _input(event):
	if event.is_action_pressed(controller.A) || event.is_action_pressed(controller.B):
		emit_signal("advance_text")
