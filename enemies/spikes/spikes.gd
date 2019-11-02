extends Enemy

enum SpikeState {shown, hidden}
var spike_state = SpikeState.hidden
var colliding_ids = {}

func _init():
	TYPE = "TRAP"
	spritedir = ""

func _ready():
	$detectionbox.connect("area_entered", self, "show_spikes")
	$detectionbox.connect("area_exited", self, "hide_spikes")
	puppet_anim = "idle"
	anim_switch("idle")
	anim.connect("animation_finished", self, "to_steady_state")
	connect("update_animation", self, "_on_update_animation")

func _on_update_animation(value):
	rset_map("puppet_anim", value)

func puppet_update():
	if anim.current_animation != puppet_anim:
		anim.play(puppet_anim)

func _process(delta):
	loop_network()

func show_spikes(area):
	if !is_actionable_collision(area):
		return
	colliding_ids[area.get_instance_id()] = true
	if spike_state != SpikeState.shown:
		spike_state = SpikeState.shown
		anim_switch("showSpikes")

func hide_spikes(area):
	if !is_actionable_collision(area):
		return
	if colliding_ids.erase(area.get_instance_id()):
		if colliding_ids.size() == 0 and spike_state != SpikeState.hidden:
			spike_state = SpikeState.hidden
			anim_switch("hideSpikes")

func to_steady_state(anim_name):
	if anim_name == "showSpikes":
		anim_switch("active")
	elif anim_name == "hideSpikes":
		anim_switch("idle")

func is_actionable_collision(area):
	if area.name != "Hitbox":
		return false
	var body = area.get_parent()
	if !body:
		return false
	if !body.get_groups().has("entity") or body.get_groups().has("item"):
		return false
	return body.get("TYPE") != TYPE
