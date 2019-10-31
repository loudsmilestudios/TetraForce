extends Node

export var count_max := 3
export var count_step := 1
var count = 0

signal counter_done


func increment(step = count_step) -> void:
	count += step
	if count >= count_max:
		emit_signal("counter_done")
