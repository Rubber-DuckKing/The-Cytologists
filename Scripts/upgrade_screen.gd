extends Node2D

signal chosen_upgrade

@export var clone_scene: PackedScene

var UPGRADES: Array = [0, 1, 2, 3, 4]
var upgrades: Array = [0, 1, 2, 3, 4]
var button0
var button1
var button2
var cell: CharacterBody2D

func new_upgrades():
	$Button0.disabled = true
	$Button1.disabled = true
	$Button2.disabled = true
	$DisabledTimer.start()
	for i in 3:
		var type = upgrades.pick_random()
		var button
		
		#finds button
		if i == 0:
			button = $Button0
			button0 = type
		elif i == 1:
			button = $Button1
			button1 = type
		elif i == 2:
			button = $Button2
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
	$Button0.disabled = false
	$Button1.disabled = false
	$Button2.disabled = false

func _on_button_0_pressed() -> void:
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
		if cell.name == "Player":
			cell.get_child(7).start()
		else:
			cell.get_child(6).start()
	else:
		if cell.name == "Player":
			cell.get_child(7).wait_time -= 10
		else:
			cell.get_child(6).wait_time -= 10
		cell.bombardment_bullet_damage += 1

func beefy():
	if !cell.has_beefy:
		cell.has_beefy = true
		if cell.name == "Player":
			cell.get_child(6).start()
		else:
			cell.get_child(5).start()
	else:
		cell.resistance += 0.05
		if cell.name == "Player":
			if cell.get_child(6).wait_time >= 0.10:
				cell.get_child(6).wait_time -= 0.10
		else:
			if cell.get_child(5).wait_time >= 0.10:
				cell.get_child(5).wait_time -= 0.10

func gang_up():
	if !cell.has_gang_up:
		cell.has_gang_up = true
	else:
		cell.gang_up_multiplier += 0.05

func fracture():
	var main = get_tree().current_scene
	
	var cell_health
	var max_cell_health
	var cell_damage
	
	if int(cell.max_health / 4.0) <= 1:
		cell_health = 1
		max_cell_health = 1
		cell.health = 1
		cell.max_health = 1
	else:
		cell_health = int(cell.health / 4.0)
		cell.health = int(cell.health / 4.0)
		max_cell_health = int(cell.max_health / 4.0)
		cell.max_health = int(cell.max_health / 4.0)
	
	if int(cell.damage / 4.0) != 0:
		cell_damage = int(cell.damage / 4.0)
		cell.damage = int(cell.damage / 4.0)
	else:
		cell_damage = 1
		cell.damage = 1
	
	cell.get_child(2).text = str(cell.health) + "/" + str(cell.max_health)
	
	for i in 3:
		var clone = clone_scene.instantiate()
		
		clone.global_position.x = main.original_pos.x + randi_range(100, 300)
		clone.global_position.y = main.original_pos.y + randi_range(100, 300)
		
		clone.health = cell_health
		clone.max_health = max_cell_health
		
		clone.damage = cell_damage
		
		clone.get_child(2).text = str(clone.health) + "/" + str(clone.max_health)
		
		clone.hide()
		
		main.add_child(clone)
		
		clone.add_to_group("cells")

func mitosis():
	var main = get_tree().current_scene
	
	var clone = clone_scene.instantiate()
	
	clone.global_position.x = main.original_pos.x + 100
	clone.global_position.y = main.original_pos.y
	
	if int(cell.max_health / 2.0) <= 1:
		cell.health = 1
		cell.max_health = 1
	else:
		cell.health = int(cell.health / 2.0)
		cell.max_health = int(cell.max_health / 2.0)
	
	clone.health = cell.health
	clone.max_health = cell.max_health
	
	cell.get_child(2).text = str(cell.health) + "/" + str(cell.max_health)
	
	clone.get_child(2).text = str(clone.health) + "/" + str(clone.max_health)
	
	clone.hide()
	
	main.add_child(clone)
	
	clone.add_to_group("cells")
