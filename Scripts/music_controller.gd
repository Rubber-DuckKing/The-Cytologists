extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer

@export var title_music: AudioStream
@export var laboratory_intro: AudioStream
@export var laboratory_loop: AudioStream
@export var to_the_wire_intro: AudioStream
@export var to_the_wire_loop: AudioStream
@export var spaceship_music: AudioStream

var pending_loop: AudioStream = null
var music_stage := ""
var title_active := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.process_mode = Node.PROCESS_MODE_ALWAYS
	music_player.volume_db = -4.0
	music_player.finished.connect(_on_music_finished)

func play_title_music() -> void:
	title_active = true
	music_stage = "title"
	pending_loop = title_music
	_play_stream(title_music, true)

func start_run_music() -> void:
	title_active = false
	play_laboratory()

func update_for_wave(wave: int) -> void:
	if title_active:
		return

	var cycle_wave := wave
	while cycle_wave > 21:
		cycle_wave -= 21

	if cycle_wave >= 15:
		if music_stage != "spaceship":
			play_spaceship()
	elif cycle_wave >= 5:
		if music_stage != "to_the_wire":
			play_to_the_wire()
	else:
		if music_stage != "laboratory":
			play_laboratory()

func play_laboratory() -> void:
	music_stage = "laboratory"
	pending_loop = laboratory_loop
	_play_stream(laboratory_intro)

func play_to_the_wire() -> void:
	music_stage = "to_the_wire"
	pending_loop = to_the_wire_loop
	_play_stream(to_the_wire_intro)

func play_spaceship() -> void:
	music_stage = "spaceship"
	pending_loop = spaceship_music
	_play_stream(spaceship_music, true)

func stop_music() -> void:
	pending_loop = null
	title_active = false
	music_stage = ""
	music_player.stop()

func _on_music_finished() -> void:
	if pending_loop != null:
		if music_player.stream != pending_loop:
			_play_stream(pending_loop, true)

func _play_stream(stream: AudioStream, should_loop: bool = false) -> void:
	if stream == null:
		return

	if stream is AudioStreamOggVorbis:
		stream.loop = should_loop
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD if should_loop else AudioStreamWAV.LOOP_DISABLED

	music_player.stop()
	music_player.stream = stream
	music_player.play()
