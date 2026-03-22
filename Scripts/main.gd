extends Node2D

var current_zoom = 1
var drag_velocity: Vector2 = Vector2(0,0)
var camera_position: Vector2
var start_pos: Vector2
var end_pos: Vector2
var camera_moving: bool = false
var can_move_camera: bool = true
var has_start_pos: bool = false
var following_player: bool = true
var enemy_time = 1.0
var enemy_amount = 5
var wave = 1
var screen_size: Vector2

func _ready() -> void:
	screen_size = get_viewport_rect().size
	get_tree().paused = true
	$DeathLabel.hide()
	start_wave()
	new_wave()

func new_wave():
	$EnemySpawner.time = enemy_time
	$EnemySpawner.max_enemies = enemy_amount
	$Player.global_position = screen_size / 2
	$Camera2D.global_position = $Player.global_position
	$GameUI.global_position.x = $Camera2D.global_position.x
	$GameUI.global_position.y = $Camera2D.global_position.y
	$Mouse.global_position = get_global_mouse_position()
	$EnemySpawner.get_child(46).start()
	get_tree().call_group("enemies", "queue_free")

func start_wave():
	$WaveStartLabel.text = "Wave " + str(wave) + "... FIGHT!"
	$WaveStartLabel.show()
	$WaveStartTimer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	$GameUI.global_position.x = $Camera2D.global_position.x
	$GameUI.global_position.y = $Camera2D.global_position.y
	$Mouse.global_position = get_global_mouse_position()
	
	if following_player:
		$Camera2D.global_position = $Player.global_position
	elif camera_moving:
		$Camera2D.global_position.x -= drag_velocity.x * delta
		$Camera2D.global_position.y -= drag_velocity.y * delta
		$GameUI.global_position.x -= drag_velocity.x * delta
		$GameUI.global_position.y -= drag_velocity.y * delta
		$Mouse.global_position.x -= drag_velocity.x * delta
		$Mouse.global_position.y -= drag_velocity.y * delta
	
	if is_wave_completed():
		wave += 1
		enemy_amount = int(enemy_amount * 1.2)
		if enemy_time > 0.25:
			enemy_time -= 0.05
		get_tree().paused = true
		$LoadingScreen.get_child(1).play("transition")
		await $LoadingScreen.get_child(1).animation_finished
		new_wave()
		$LoadingScreen.get_child(1).play_backwards("transition")
		await $LoadingScreen.get_child(1).animation_finished
		start_wave()
		

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMagnifyGesture:
		current_zoom *= event.factor
		if current_zoom > 10:
			current_zoom = 10
		elif current_zoom < 0.25:
			current_zoom = 0.25
		$Camera2D.zoom.x = current_zoom
		$Camera2D.zoom.y = current_zoom
		$Mouse.scale.x = 1.0/current_zoom
		$Mouse.scale.y = 1.0/current_zoom
		$GameUI.scale.x = 1.0/current_zoom
		$GameUI.scale.y = 1.0/current_zoom

func distance(pos1: Vector2, pos2: Vector2) -> float:
	return sqrt(pow((pos2.x - pos1.x), 2) + pow((pos2.y - pos2.y), 2))

func _input(event: InputEvent) -> void:
	if event is InputEventScreenDrag and can_move_camera:
		drag_velocity = event.velocity
		drag_velocity.normalized()
		end_pos = event.position
	if event is InputEventMouseButton and can_move_camera:
		if event.pressed:
			start_pos = event.position
			has_start_pos = true
		if event.is_released() and has_start_pos:
			var dist = distance(start_pos, end_pos)
			if dist/1000 > 0:
				$Camera2D/Timer.wait_time = dist/1000
			else:
				$Camera2D/Timer.wait_time = 0.001
			$Camera2D/Timer.start()
			camera_moving = true
			following_player = false
			has_start_pos = false

func is_wave_completed():
	var all_dead = true
	var enemies = get_tree().get_nodes_in_group("enemies")
	#check if all enemies have spawned first
	if enemies.size() == enemy_amount:
		for e in enemies:
			if e.alive:
				all_dead = false
		return all_dead
	else:
		return false

func _on_timer_timeout() -> void:
	camera_moving = false

func _on_game_ui_camera_reset() -> void:
	following_player = true

func _on_area_2d_area_shape_entered(_area_rid: RID, _area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	can_move_camera = false

func _on_area_2d_area_shape_exited(_area_rid: RID, _area: Area2D, _area_shape_index: int, _local_shape_index: int) -> void:
	can_move_camera = true

func _on_wave_start_timer_timeout() -> void:
	get_tree().paused = false
	$WaveStartLabel.hide()

func _on_player_main_died() -> void:
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("bullets", "queue_free")
	get_tree().paused = true
	$GameUI.hide()
	$DeathLabel.text = "You Died!\nSurvived: " + str(wave - 1) + " wave(s)"
	$DeathLabel.show()
