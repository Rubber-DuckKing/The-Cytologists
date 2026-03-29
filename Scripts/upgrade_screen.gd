extends CanvasLayer

signal chosen_upgrade

@export var clone_scene: PackedScene

var UPGRADES: Array = [0, 1, 2, 3, 4]
var upgrades: Array = [0, 1, 2, 3, 4]
var button0
var button1
var button2
var cell: CharacterBody2D

const MIN_SPLIT_HEALTH := 1

func new_upgrades():
	$UIRoot/Button0.disabled = true
	$UIRoot/Button1.disabled = true
	$UIRoot/Button2.disabled = true
	$UIRoot/DisabledTimer.start()
	for i in 3:
		var type = upgrades.pick_random()
		var button
		
		#finds button
		if i == 0:
			button = $UIRoot/Button0
			button0 = type
		elif i == 1:
			button = $UIRoot/Button1
			button1 = type
		elif i == 2:
			button = $UIRoot/Button2
			button2 = type
		
		#changes labels
		if type == 0:
			button.get_child(0).text = "Splits current cell into 2 smaller cells with reduced health"
		elif type == 1:
			button.get_child(0).text = "Splits current cell into 4 smaller cells with reduced health and damage"
		elif type == 2:
			button.get_child(0).text = "This cell resists oncoming damage more and repairs itself over time"
		elif type == 3:
			button.get_child(0).text = "This cell periodically ejects small exploding seeking cells"
		elif type == 4:
			button.get_child(0).text = "This cell gains more damage the more total cells there are"
		upgrades.erase(type)
	
	#reset upgrades
	upgrades.clear()
	for i in UPGRADES:
		upgrades.append(UPGRADES[i])

func set_cell(cell_: CharacterBody2D):
	cell = cell_

func _on_disabled_timer_timeout() -> void:
	$UIRoot/Button0.disabled = false
	$UIRoot/Button1.disabled = false
	$UIRoot/Button2.disabled = false

func _on_button_0_pressed() -> void:
	_play_confirm_sfx()
	if button0 == 0:
		mitosis()
	elif button0 == 1:
		fracture()
	elif button0 == 2:
		beefy()
	elif button0 == 3:
		bombardment()
	elif button0 == 4:
		gang_up()
	chosen_upgrade.emit()


func _on_button_1_pressed() -> void:
	_play_confirm_sfx()
	if button1 == 0:
		mitosis()
	elif button1 == 1:
		fracture()
	elif button1 == 2:
		beefy()
	elif button1 == 3:
		bombardment()
	elif button1 == 4:
		gang_up()
	chosen_upgrade.emit()


func _on_button_2_pressed() -> void:
	_play_confirm_sfx()
	if button2 == 0:
		mitosis()
	elif button2 == 1:
		fracture()
	elif button2 == 2:
		beefy()
	elif button2 == 3:
		bombardment()
	elif button2 == 4:
		gang_up()
	chosen_upgrade.emit()

func bombardment():
	if !cell.has_bombardment:
		cell.has_bombardment = true
		cell.bombardment_level = 1
		cell.bombardment_bullet_damage = max(int(cell.damage), int(cell.bombardment_bullet_damage))
		cell.get_node("BombardmentTimer").start()
	else:
		cell.bombardment_level += 1
		cell.get_node("BombardmentTimer").wait_time -= 10
		cell.bombardment_bullet_damage = int(round(cell.bombardment_bullet_damage * 1.25))

func beefy():
	if !cell.has_beefy:
		cell.has_beefy = true
		cell.beefy_level = 1
		cell.get_node("RegenerateTimer").start()
	else:
		cell.beefy_level += 1
		cell.resistance += 0.05
		var regenerate_timer: Timer = cell.get_node("RegenerateTimer")
		if regenerate_timer.wait_time >= 0.10:
			regenerate_timer.wait_time -= 0.10

func gang_up():
	if !cell.has_gang_up:
		cell.has_gang_up = true
		cell.gang_up_level = 1
	else:
		cell.gang_up_level += 1
		cell.gang_up_multiplier += 0.05

func fracture():
	var main = get_tree().current_scene
	main._play_sfx("play_cell_split")
	
	var split_stats = _build_split_stats(4)
	var cell_health = split_stats["health"]
	
	cell.health = cell_health
	
	for i in 3:
		var clone = clone_scene.instantiate()
		
		clone.global_position.x = main.original_pos.x + randi_range(100, 300)
		clone.global_position.y = main.original_pos.y + randi_range(100, 300)
		
		clone.health = cell_health
		clone.damage = cell.damage
		clone.max_health = cell.max_health
		clone.has_gang_up = cell.has_gang_up
		clone.gang_up_multiplier = cell.gang_up_multiplier
		clone.gang_up_level = cell.gang_up_level
		clone.has_beefy = cell.has_beefy
		clone.resistance = cell.resistance
		clone.beefy_level = cell.beefy_level
		clone.has_bombardment = cell.has_bombardment
		clone.bombardment_bullet_damage = cell.bombardment_bullet_damage
		clone.bombardment_level = cell.bombardment_level
		
		clone.hide()
		
		main.add_child(clone)
		
		clone.add_to_group("cells")

func mitosis():
	var main = get_tree().current_scene
	main._play_sfx("play_cell_split")
	
	var clone = clone_scene.instantiate()
	var split_stats = _build_split_stats(2)
	
	clone.global_position.x = main.original_pos.x + 100
	clone.global_position.y = main.original_pos.y
	
	cell.health = split_stats["health"]
	
	clone.health = cell.health
	clone.damage = cell.damage
	clone.max_health = cell.max_health
	clone.has_gang_up = cell.has_gang_up
	clone.gang_up_multiplier = cell.gang_up_multiplier
	clone.gang_up_level = cell.gang_up_level
	clone.has_beefy = cell.has_beefy
	clone.resistance = cell.resistance
	clone.beefy_level = cell.beefy_level
	clone.has_bombardment = cell.has_bombardment
	clone.bombardment_bullet_damage = cell.bombardment_bullet_damage
	clone.bombardment_level = cell.bombardment_level
	
	clone.hide()
	
	main.add_child(clone)
	
	clone.add_to_group("cells")

func _build_split_stats(divisor: int) -> Dictionary:
	var split_health = max(int(ceil(cell.health / float(divisor))), MIN_SPLIT_HEALTH)
	
	return {
		"health": min(split_health, cell.max_health)
	}

func _play_confirm_sfx() -> void:
	var main = get_tree().current_scene
	if main != null and main.has_method("_play_sfx"):
		main._play_sfx("play_ui_click")
