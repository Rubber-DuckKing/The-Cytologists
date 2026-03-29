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
var level = 1
var next_xp = 30
var xp_multiplier = 1.75
var original_pos: Vector2
var screen_size: Vector2
var chosen_cell: CharacterBody2D
var sfx_controller: Node
var inspect_mode := false
var upgrade_selection_active := false

const TRANSITION_SPEED_SCALE := 2.5
const SFX_CONTROLLER_SCRIPT = preload("res://Scripts/sfx_controller.gd")
const CELL_INSPECT_RADIUS := 96.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	screen_size = get_viewport_rect().size
	get_tree().paused = true
	$DeathLabel.hide()
	$RestartButton.hide()
	$InspectUI.hide()
	$UpgradeBackground.hide()
	$GameUI.hide()
	$UpgradeScreen.hide()
	if $GameUI.has_node("CellBarTemplate"):
		$GameUI.get_node("CellBarTemplate").hide()
	sfx_controller = SFX_CONTROLLER_SCRIPT.new()
	sfx_controller.name = "SFXController"
	add_child(sfx_controller)
	$LoadingScreen.get_node("AnimationPlayer").speed_scale = TRANSITION_SPEED_SCALE
	$Player.get_node("Camera2D").zoom.x = 1.0
	$Player.get_node("Camera2D").zoom.y = 1.0
	$MusicController.play_title_music()
	call_deferred("refresh_hud")

func new_wave():
	$GameUI.show()
	$Player.get_node("Camera2D").zoom.x = 2.0
	$Player.get_node("Camera2D").zoom.y = 2.0
	$Player.get_node("Camera2D").global_position = $Player.global_position
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
	refresh_hud()

func start_wave():
	$WaveStartLabel.text = "Wave " + str(wave) + "... FIGHT!"
	$WaveStartLabel.show()
	$WaveStartTimer.start()

func _process(_delta: float) -> void:
	_update_attack_hud()
	_update_inspect_tooltip()
	if !get_tree().paused and is_wave_completed():
		await advance_wave()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and !event.echo and event.keycode == KEY_F6:
		if $StartScreen.visible:
			return
		if get_tree().paused:
			return
		await advance_wave()
	elif event is InputEventKey and event.pressed and !event.echo and event.keycode == KEY_TAB:
		_toggle_inspect_mode()

func distance(pos1: Vector2, pos2: Vector2) -> float:
	return pos1.distance_to(pos2)

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
	refresh_hud()
	if xp >= next_xp:
		stat_upgrade()
		upgrade()

func stat_upgrade():
	for cell in get_tree().get_nodes_in_group("cells"):
		cell.max_health *= 1.15
		cell.health *= 1.15
		cell.damage *= 1.2
		cell.bombardment_bullet_damage = max(int(round(cell.bombardment_bullet_damage * 1.2)), int(cell.damage))
	refresh_hud()

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
	inspect_mode = false
	upgrade_selection_active = false
	$InspectUI.hide()
	$MusicController.stop_music()
	_play_sfx("play_game_over")
	$GameUI.clear_cell_bars()
	$GameUI.hide()
	$DeathLabel.text = "You Died!\nSurvived: " + str(wave - 1) + " wave(s)"
	$DeathLabel.show()
	$RestartButton.show()
	$Player.global_position = screen_size / 2

func connect_cell(clone : CharacterBody2D):
	clone.selected_for_upgrade.connect(_on_cell_selected_for_upgrade)

func upgrade():
	get_tree().paused = true
	upgrade_selection_active = true
	level += 1
	next_xp = int(next_xp * xp_multiplier)
	$"GameUI".hide()
	refresh_hud()
	for cell in get_tree().get_nodes_in_group("cells"):
		cell.get_node("UpgradeButton").show()
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.hide()
	for bullet in get_tree().get_nodes_in_group("bullets"):
		bullet.hide()
	$Player.get_node("Camera2D").zoom.x = 1.0
	$Player.get_node("Camera2D").zoom.y = 1.0

func _on_cell_selected_for_upgrade(cell: CharacterBody2D):
	upgrade_selection_active = false
	chosen_cell = cell
	original_pos = cell.global_position
	$UpgradeScreen.set_cell(cell)
	$InspectUI.hide()
	for cell_ in get_tree().get_nodes_in_group("cells"):
		var upgrade_button: Button = cell_.get_node("UpgradeButton")
		upgrade_button.button_pressed = false
		upgrade_button.hide()
		if cell_ != cell:
			cell_.hide()
	$LoadingScreen.get_child(1).play("transition")
	_play_sfx("play_upgrade_open")
	await $LoadingScreen.get_child(1).animation_finished
	$Player.get_node("Camera2D").position_smoothing_enabled = false
	$UpgradeBackground.show()
	cell.global_position = screen_size / 2
	cell.global_position.x -= 300
	if cell.global_position.x < 3000 - cell.global_position.x:
		$Player.get_node("Camera2D").global_position = Vector2(cell.global_position.x + 500, cell.global_position.y)
	else:
		$Player.get_node("Camera2D").global_position = Vector2(cell.global_position.x - 500, cell.global_position.y)
	$Player.get_node("Camera2D").zoom.x = 2.0
	$Player.get_node("Camera2D").zoom.y = 2.0
	upgrade_select()
	$LoadingScreen.get_child(1).play_backwards("transition")
	await $LoadingScreen.get_child(1).animation_finished

func upgrade_select():
	$Player.get_node("Camera2D").zoom.x = 2.0
	$Player.get_node("Camera2D").zoom.y = 2.0
	$UpgradeScreen.new_upgrades()
	$UpgradeScreen.show()

func _on_upgrade_screen_chosen_upgrade() -> void:
	$LoadingScreen.get_child(1).play("transition")
	_play_sfx("play_ui_click")
	await $LoadingScreen.get_child(1).animation_finished
	$"GameUI".show()
	chosen_cell.global_position = original_pos
	for cell in get_tree().get_nodes_in_group("cells"):
		cell.show()
	$Player.get_node("Camera2D").global_position = $Player.global_position
	$UpgradeBackground.hide()
	$UpgradeScreen.hide()
	upgrade_selection_active = false
	$InspectUI.hide()
	$LoadingScreen.get_child(1).play_backwards("transition")
	await $LoadingScreen.get_child(1).animation_finished
	get_tree().paused = false
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy.alive:
			enemy.show()
	for bullet in get_tree().get_nodes_in_group("bullets"):
		bullet.show()
	refresh_hud()

func _on_start_button_pressed() -> void:
	$LoadingScreen.get_child(1).play("transition")
	_play_sfx("play_ui_click")
	_play_sfx("play_ui_transition")
	await $LoadingScreen.get_child(1).animation_finished
	$StartScreen.hide()
	$StartButton.hide()
	$CreditsLabel.hide()
	$GameLabel.hide()
	$RestartButton.hide()
	inspect_mode = false
	upgrade_selection_active = false
	$InspectUI.hide()
	$MusicController.start_run_music()
	new_wave()
	$LoadingScreen.get_child(1).play_backwards("transition")
	await $LoadingScreen.get_child(1).animation_finished
	start_wave()

func refresh_hud() -> void:
	$GameUI.update_xp_display(xp, next_xp, level)
	$GameUI.refresh_cell_bars(get_tree().get_nodes_in_group("cells"))
	_update_attack_hud()

func advance_wave() -> void:
	wave += 1
	$MusicController.update_for_wave(wave)
	enemy_amount = int(enemy_amount * 1.2)
	if enemy_time > 0.25:
		enemy_time -= 0.05
	$EnemySpawner.health *= 1.2
	$EnemySpawner.damage *= 1.3
	$EnemySpawner.xp_amount *= 1.2
	get_tree().paused = true
	$LoadingScreen.get_child(1).play("transition")
	_play_sfx("play_ui_transition")
	await $LoadingScreen.get_child(1).animation_finished
	new_wave()
	$LoadingScreen.get_child(1).play_backwards("transition")
	await $LoadingScreen.get_child(1).animation_finished
	start_wave()

func _on_restart_button_pressed() -> void:
	_play_sfx("play_ui_click")
	get_tree().paused = false
	get_tree().reload_current_scene()

func _play_sfx(method_name: String) -> void:
	if sfx_controller != null and sfx_controller.has_method(method_name):
		sfx_controller.call(method_name)

func _update_attack_hud() -> void:
	if !$GameUI.visible:
		return
	var attack_timer: Timer = $Player.get_node_or_null("AttackTimer")
	if attack_timer == null:
		return
	$GameUI.update_attack_bar(attack_timer.time_left, attack_timer.wait_time, $Player.can_attack)

func _toggle_inspect_mode() -> void:
	if $StartScreen.visible or $DeathLabel.visible or $RestartButton.visible:
		return
	if get_tree().paused and !inspect_mode:
		return
	if upgrade_selection_active:
		return
	if $UpgradeScreen.visible:
		return
	inspect_mode = !inspect_mode
	get_tree().paused = inspect_mode
	if !inspect_mode:
		$InspectUI.hide()

func _update_inspect_tooltip() -> void:
	if !_is_inspecting():
		$InspectUI.hide()
		return
	
	var hovered_cell = _get_hovered_cell()
	if hovered_cell == null:
		$InspectUI.hide()
		return
	
	var tooltip_label: Label = $InspectUI.get_node("Panel/Margin/InfoLabel")
	tooltip_label.text = _build_cell_inspect_text(hovered_cell)
	_position_inspect_tooltip()
	$InspectUI.show()

func _is_inspecting() -> bool:
	return upgrade_selection_active or $UpgradeScreen.visible or inspect_mode

func _get_hovered_cell():
	var mouse_world := get_global_mouse_position()
	var closest_cell: CharacterBody2D = null
	var closest_distance := CELL_INSPECT_RADIUS
	
	for cell in get_tree().get_nodes_in_group("cells"):
		if cell == null or !is_instance_valid(cell):
			continue
		if !cell.visible:
			continue
		var cell_distance = cell.global_position.distance_to(mouse_world)
		if cell_distance <= closest_distance:
			closest_distance = cell_distance
			closest_cell = cell
	
	return closest_cell

func _build_cell_inspect_text(cell: CharacterBody2D) -> String:
	var display_name := "CELL"
	if $GameUI.has_method("get_display_name_for_cell"):
		display_name = $GameUI.get_display_name_for_cell(cell)
	var attack_timer: Timer = cell.get_node_or_null("AttackTimer")
	var attack_cooldown_text := "ATK CD: --"
	if attack_timer != null:
		attack_cooldown_text = "ATK CD: " + str(snappedf(attack_timer.wait_time, 0.01)) + "s"
	
	var lines := [
		display_name,
		"HP: " + str(int(cell.health)) + " / " + str(int(cell.max_health)),
		"DMG: " + str(int(cell.damage)),
		attack_cooldown_text,
		"",
		"TRAITS:"
	]
	
	var trait_lines := _get_trait_lines(cell)
	if trait_lines.is_empty():
		lines.append("- None")
	else:
		lines.append_array(trait_lines)
	
	return "\n".join(lines)

func _get_trait_lines(cell: CharacterBody2D) -> Array[String]:
	var traits: Array[String] = []
	if cell.has_method("get"):
		if cell.get("beefy_level") > 0:
			traits.append("- Beefy x " + str(cell.get("beefy_level")))
		if cell.get("bombardment_level") > 0:
			traits.append("- Bombardment x " + str(cell.get("bombardment_level")))
		if cell.get("gang_up_level") > 0:
			traits.append("- Gang Up x " + str(cell.get("gang_up_level")))
	return traits

func _position_inspect_tooltip() -> void:
	var panel: Control = $InspectUI.get_node("Panel")
	var mouse_pos := get_viewport().get_mouse_position() + Vector2(36, 24)
	var viewport_size := get_viewport_rect().size
	var panel_size := panel.size
	
	if mouse_pos.x + panel_size.x > viewport_size.x - 24:
		mouse_pos.x = viewport_size.x - panel_size.x - 24
	if mouse_pos.y + panel_size.y > viewport_size.y - 24:
		mouse_pos.y = viewport_size.y - panel_size.y - 24
	
	panel.position = mouse_pos
