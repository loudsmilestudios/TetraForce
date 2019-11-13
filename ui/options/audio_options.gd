extends Tabs

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	$master_slider.value = get_node("/root/settings").get_pref("volume_master")
	$effects_slider.value = get_node("/root/settings").get_pref("volume_effects")
	$music_slider.value = get_node("/root/settings").get_pref("volume_music")
	
	$master_pct.text = str($master_slider.value * 100) + "%"
	$effect_pct.text = str($effects_slider.value *100) + "%"
	$music_pct.text = str($music_slider.value * 100) + "%"

func _on_master_slider_value_changed(value):
	$master_pct.text = str($master_slider.value * 100) + "%"
	music.change_volume($master_slider.value * $music_slider.value)
	get_node("/root/sfx").change_volume($master_slider.value * $effects_slider.value)


func _on_effects_slider_value_changed(value):
	$effect_pct.text = str($effects_slider.value *100) + "%"
	get_node("/root/sfx").change_volume($master_slider.value * $effects_slider.value)


func _on_music_slider_value_changed(value):
	$music_pct.text = str($music_slider.value * 100) + "%"
	music.change_volume($master_slider.value * $music_slider.value)

func _on_save_btn_pressed():
	get_node("/root/settings").set_pref("volume_master", $master_slider.value)
	get_node("/root/settings").set_pref("volume_effects", $effects_slider.value)
	get_node("/root/settings").set_pref("volume_music", $music_slider.value)
