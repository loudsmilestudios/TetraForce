extends Node

onready var music = AudioStreamPlayer.new()
var current_song = ""
var gameover = false

const DEFAULT_SFX_VOLUME = -15
const DEFAULT_MUSIC_VOLUME = -20
const QUIET_MUSIC_VOLUME = -27.5

var music_fadingout = false
var music_volume = DEFAULT_MUSIC_VOLUME

func _ready():
	add_child(music)

func _process(delta):
	if music_fadingout:
		music_volume -= delta * 30
	music.volume_db = lerp(music.volume_db, music_volume, 0.1)

func fadeout_music():
	music_fadingout = true

func set_music(song, musicfx = ""):
	music_fadingout = false
	if gameover == false:
		music_volume = DEFAULT_MUSIC_VOLUME
		if song != current_song:
			var path = str("res://sound/music/", song, ".ogg")
			current_song = song
			music.stream = load(path)
			music.play()
		if musicfx == "quiet":
			music_volume = QUIET_MUSIC_VOLUME

func play(sound, volume=0):
	var path = str("res://sound/sfx/", sound, ".ogg")
	var new_sound = AudioStreamPlayer.new()
	get_tree().get_root().add_child(new_sound)
	new_sound.set_stream(load(path))
	new_sound.set_volume_db(DEFAULT_SFX_VOLUME + volume)
	new_sound.connect("finished", new_sound, "queue_free")
	new_sound.play()
