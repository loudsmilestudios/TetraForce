extends Node

onready var music = AudioStreamPlayer.new()
# Music that's being faded out is transferred here by swapping instances around.
# This implies that if a music set occurs too immediately, a cross-fade occurs.
onready var _music_fading = AudioStreamPlayer.new()
var current_song = ""
var gameover = false

const DEFAULT_SFX_VOLUME = -15
const DEFAULT_MUSIC_VOLUME = -20
const QUIET_MUSIC_VOLUME = -27.5

# Godot uses decibels as the measurement.
# In decibels, '-inf' is silent.
# Actually using this would mess up all of the calculations.
# Therefore, define some value that is considered effectively silent.
const SILENT_MUSIC_VOLUME = -50

var music_volume = DEFAULT_MUSIC_VOLUME

func _ready():
	add_child(music)
	add_child(_music_fading)

func _process(delta):
	if _music_fading.playing:
		_music_fading.volume_db -= delta * 30
		if _music_fading.volume_db <= SILENT_MUSIC_VOLUME:
			# This makes sure the old track gets unloaded eventually.
			# But more importantly, it allows a new track to take over.
			_music_fading.stop()
			_music_fading.stream = null
	# Start any queued music track.
	if not _music_fading.playing:
		if music.stream != null:
			if not music.playing:
				music.play()
	# If the music's playing, manage volume.
	if music.playing:
		music.volume_db = lerp(music.volume_db, music_volume, 0.1)

func fadeout_music():
	current_song = ""
	# Importantly, try to deduplicate repeated calls.
	# If the music never actually started, this instance is reusable as-is.
	if music.playing:
		# This instance is in-use.
		# Swap it into the fading track position.
		# Whatever's in the fading track position will be shutdown.
		var tmp = music
		music = _music_fading
		_music_fading = tmp
	# Clean the existing track instance so it's like-new.
	music.stop()
	music.stream = null
	music.volume_db = SILENT_MUSIC_VOLUME

func set_music(song, musicfx = ""):
	var fx = {}
	for v in musicfx.split(","):
		fx[v] = true
	if gameover == false:
		music_volume = DEFAULT_MUSIC_VOLUME
		var song_change = song != current_song
		if song_change:
			# shift out the existing track
			fadeout_music()
			if song != "":
				var path = str("res://sound/music/", song, ".ogg")
				music.stream = load(path)
				# Music will be started when the previous track is gone.
			current_song = song
		# FX handling
		if fx.has("quiet"):
			music_volume = QUIET_MUSIC_VOLUME
		if song_change:
			# fadein in particular is only usable on a song change,
			#  because it *only* affects initial fade-in.
			# Otherwise it would affect volume transitions.
			# Not on by default because it cuts off early notes.
			# Must be placed after all music_volume controllers.
			if not fx.has("fadein"):
				# Start the music at full volume.
				music.volume_db = music_volume
		if fx.has("immediate") and not music.playing:
			# Don't wait for fade-out.
			# Must be at the end.
			music.play()

func play(sound, volume=0):
	var path = str("res://sound/sfx/", sound, ".ogg")
	var new_sound = AudioStreamPlayer.new()
	get_tree().get_root().add_child(new_sound)
	new_sound.set_stream(load(path))
	new_sound.set_volume_db(DEFAULT_SFX_VOLUME + volume)
	new_sound.connect("finished", new_sound, "queue_free")
	new_sound.play()
