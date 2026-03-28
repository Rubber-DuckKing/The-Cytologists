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
var xp = 0
var next_xp = 30
var xp_multiplier = 1.75
var original_pos: Vector2
var screen_size: Vector2
var chosen_cell: CharacterBody2D

func _ready() -> void:
	screen_size = get_viewport_rect().size
	get_tree().paused = true
	$DeathLabel.hide()
	$UpgradeBackground.hide()
	$GameUI.hide()
	$Player.get_child(3).zoom.x = 1.0
	$Player.get_child(3).zoom.y = 1.0

func new_wave():
	$GameUI.show()
	$Player.get_child(3).zoom.x = 2.0
	$Player.get_child(3).zoom.y = 2.0
	$Player.get_child(3).global_position = $Player.global_position
	$EnemySpawner.time = enemy_time
	$EnemySpawner.max_enemies = enemy_amount
	for cell in get_tree().get_nodes_in_group("cells"):
		if cell.name == "Player":
			cell.global_position = screen_size / 2
		else:
			cell.global_position.x = (screen_size.x + randi_range(100, 200))/2
			cell.global_position.y = (screen_size.y + randi_range(100, 200))/2
	$EnemySpawner.get_child(46).start()
	get_tree().call_group("enemies", "queue_free")

func start_wave():
	$WaveStartLabel.text = "Wave " + str(wave) + "... FIGHT!"
	$WaveStartLabel.show()
	$WaveStartTimer.start()

func _process(_delta: float) -> void:
	if is_wave_completed():
		wave += 1
		enemy_amount = int(enemy_amount * 1.2)
		if enemy_time > 0.25:
			enemy_time -= 0.05
		$EnemySpawner.health *= 1.2
		$EnemySpawner.damage *= 1.3
		$EnemySpawner.xp_amount *= 1.2
		get_tree().paused = true
		$LoadingScreen.get_child(1).play("transition")
		await $LoadingScreen.get_child(1).animation_finished
		new_wave()
		$LoadingScreen.get_child(1).play_backwards("transition")
		await $LoadingScreen.get_child(1).animation_finished
		start_wave()

func distance(pos1: Vector2, pos2: Vector2) -> float:
	return sqrt(pow((pos2.x - pos1.x), 2) + pow((pos2.y - pos2.y), 2))

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

func add_xp(xp_amount: int):
	xp += xp_amount
	$"GameUI".get_child(0).text = "XP : " + str(xp) + "/" + str(next_xp)
	if xp >= next_xp:
		stat_upgrade()
		upgrade()

func stat_upgrade():
	for cell in get_tree().get_nodes_in_group("cells"):
		cell.max_health *= 1.15
		cell.health *= 1.15
		cell.damage *= 1.2
		cell.get_child(2).text = str(int(cell.health)) + "/" + str(int(cell.max_health))

func _on_wave_start_timer_timeout() -> void:
	get_tree().paused = false
	$WaveStartLabel.hide()

func _on_player_main_died() -> void:
	get_tree().call_group("enemies", "queue_free")
	get_tree().call_group("bullets", "queue_free")
	for cell in get_tree().get_nodes_in_group("cells"):
		if cell.name != "Player":
			cell.queue_free()
	get_tree().paused = true
	$GameUI.hide()
	$DeathLabel.text = "You Died!\nSurvived: " + str(wave - 1) + " wave(s)"
	$DeathLabel.show()
	$Player.global_position = screen_size / 2

func connect_cell(clone : CharacterBody2D):
	clone.selected_for_upgrade.connect(_on_cell_selected_for_upgrade)

func upgrade():
	get_tree().paused = true
	next_xp = int(next_xp * xp_multiplier)
	$"GameUI".hide()
	$"GameUI".get_child(0).text = "XP : " + str(xp) + "/" + str(next_xp)
	for cell in get_tree().get_nodes_in_group("cells"):
		if cell.name == "Player":
			cell.get_child(5).show()
		else:
			cell.get_child(4).show()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.hide()
	for bullet in get_tree().get_nodes_in_group("bullets"):
		bullet.hide()
	$Player.get_child(3).zoom.x = 1.0
	$Player.get_child(3).zoom.y = 1.0

func _on_cell_selected_for_upgrade(cell: CharacterBody2D):
	chosen_cell = cell
	original_pos = cell.global_position
	cell.get_child(2).hide()
	$UpgradeScreen.set_cell(cell)
	for cell_ in get_tree().get_nodes_in_group("cells"):
		if cell_.name == "Player":
			cell_.get_child(5).button_pressed = false
			cell_.get_child(5).hide()
		else:
			cell_.get_child(4).button_pressed = false
			cell_.get_child(4).hide()
		if cell_ != cell:
			cell_.hide()
	$LoadingScreen.get_child(1).play("transition")
	await $LoadingScreen.get_child(1).animation_finished
	$Player.get_child(3).position_smoothing_enabled = false
	$UpgradeBackground.show()
	cell.global_position = screen_size / 2
	cell.global_position.x -= 300
	if cell.global_position.x < 3000 - cell.global_position.x:
		$Player.get_child(3).global_position = Vector2(cell.global_position.x + 500, cell.global_position.y)
	else:
		$Player.get_child(3).global_position = Vector2(cell.global_position.x - 500, cell.global_position.y)
	$Player.get_child(3).zoom.x = 2.0
	$Player.get_child(3).zoom.y = 2.0
	upgrade_select()
	$LoadingScreen.get_child(1).play_backwards("transition")
	await $LoadingScreen.get_child(1).animation_finished

func upgrade_select():
	$Player.get_child(3).zoom.x = 2.0
	$Player.get_child(3).zoom.y = 2.0
	$UpgradeScreen.new_upgrades()
	$UpgradeScreen.global_position.x = $Player.get_child(3).global_position.x + 100
	$UpgradeScreen.global_position.y = $Player.get_child(3).global_position.y
	$UpgradeScreen.show()

func _on_upgrade_screen_chosen_upgrade() -> void:
	$LoadingScreen.get_child(1).play("transition")
	await $LoadingScreen.get_child(1).animation_finished
	$"GameUI".show()
	chosen_cell.global_position = original_pos
	chosen_cell.get_child(2).show()
	for cell in get_tree().get_nodes_in_group("cells"):
		cell.show()
	$Player.get_child(3).global_position = $Player.global_position
	$UpgradeBackground.hide()
	$UpgradeScreen.hide()
	$LoadingScreen.get_child(1).play_backwards("transition")
	await $LoadingScreen.get_child(1).animation_finished
	get_tree().paused = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.alive:
			enemy.show()
	for bullet in get_tree().get_nodes_in_group("bullets"):
		bullet.show()

func _on_start_button_pressed() -> void:
	$LoadingScreen.get_child(1).play("transition")
	await $LoadingScreen.get_child(1).animation_finished
	$StartScreen.hide()
	$StartButton.hide()
	$CreditsLabel.hide()
	$GameLabel.hide()
	new_wave()
	$LoadingScreen.get_child(1).play_backwards("transition")
	await $LoadingScreen.get_child(1).animation_finished
	start_wave()
