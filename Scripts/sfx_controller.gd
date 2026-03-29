extends Node

const UI_CLICK = preload("res://Assets/Audio/SFX/ui_click.wav")
const UI_TRANSITION = preload("res://Assets/Audio/SFX/ui_transition.wav")
const UPGRADE_OPEN = preload("res://Assets/Audio/SFX/upgrade_open.wav")
const ENEMY_SHOT = preload("res://Assets/Audio/SFX/enemy_shot.wav")
const PLAYER_HIT = preload("res://Assets/Audio/SFX/player_hit.wav")
const ENEMY_HIT = preload("res://Assets/Audio/SFX/enemy_hit.wav")
const ENEMY_DEATH = preload("res://Assets/Audio/SFX/enemy_death.wav")
const CELL_SPLIT = preload("res://Assets/Audio/SFX/cell_split.wav")
const BOMBARDMENT_LAUNCH = preload("res://Assets/Audio/SFX/bombardment_launch.wav")
const GAME_OVER = preload("res://Assets/Audio/SFX/game_over.wav")

func play_ui_click() -> void:
	_play_one_shot(UI_CLICK, -2.0)

func play_ui_transition() -> void:
	_play_one_shot(UI_TRANSITION, -6.0)

func play_upgrade_open() -> void:
	_play_one_shot(UPGRADE_OPEN, -4.0)

func play_enemy_shot() -> void:
	_play_one_shot(ENEMY_SHOT, -6.0)

func play_player_hit() -> void:
	_play_one_shot(PLAYER_HIT, -4.0)

func play_enemy_hit() -> void:
	_play_one_shot(ENEMY_HIT, -6.0)

func play_enemy_death() -> void:
	_play_one_shot(ENEMY_DEATH, -2.0)

func play_cell_split() -> void:
	_play_one_shot(CELL_SPLIT, -6.0)

func play_bombardment_launch() -> void:
	_play_one_shot(BOMBARDMENT_LAUNCH, -6.0)

func play_game_over() -> void:
	_play_one_shot(GAME_OVER, 0.0)

func _play_one_shot(stream: AudioStream, volume_db: float = 0.0) -> void:
	if stream == null:
		return
	
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(player)
	player.play()
	
	var cleanup_delay := 0.2
	if stream.has_method("get_length"):
		cleanup_delay = max(stream.get_length() + 0.05, 0.2)
	var timer := get_tree().create_timer(cleanup_delay, true)
	timer.timeout.connect(func():
		if is_instance_valid(player):
			player.queue_free()
	)
