extends CanvasLayer

signal chosen_upgrade
signal devour_requested(target_cell: CharacterBody2D)

@export var clone_scene: PackedScene

const UPGRADE_MITOSIS := 0
const UPGRADE_FRACTURE := 1
const UPGRADE_BEEFY := 2
const UPGRADE_BOMBARDMENT := 3
const UPGRADE_GANG_UP := 4
const UPGRADE_MUTATE := 5
const UPGRADE_EVOLVE := 6
const UPGRADE_DEVOUR := 7
const UPGRADE_MITOCHONDRIA := 8
const UPGRADE_ACCELERANT := 9

const MUTATION_REGENERATION: StringName = &"regeneration"
const MUTATION_VOLATILE: StringName = &"volatile"
const MUTATION_INFLUENTIAL: StringName = &"influential"
const MUTATION_CONTAGIOUS: StringName = &"contagious"
const MUTATION_TISSUE_REPAIR: StringName = &"tissue_repair"
const MUTATION_PARALYSIS: StringName = &"paralysis"

const UPGRADE_LABELS := {
	UPGRADE_MITOSIS: "Splits current cell into 2 smaller cells with reduced health",
	UPGRADE_FRACTURE: "Splits current cell into 4 smaller cells with reduced health and damage",
	UPGRADE_BEEFY: "This cell resists oncoming damage more and repairs itself over time",
	UPGRADE_BOMBARDMENT: "This cell periodically ejects small exploding seeking cells",
	UPGRADE_GANG_UP: "This cell gains more damage the more total cells there are",
	UPGRADE_MUTATE: "This cell gains a random mutation",
	UPGRADE_EVOLVE: "This cell becomes a eukaryote and gains a random mutation",
	UPGRADE_DEVOUR: "Sacrifice one of your cells, and mutate and full heal another",
	UPGRADE_MITOCHONDRIA: "Mutations are twice as effective on the chosen cell",
	UPGRADE_ACCELERANT: "Poison is twice as effective on all enemies"
}

const UPGRADE_ICONS := {
	UPGRADE_MITOSIS: preload("res://Assets/Cards/mitosis.png"),
	UPGRADE_FRACTURE: preload("res://Assets/Cards/fracture.png"),
	UPGRADE_BEEFY: preload("res://Assets/Cards/beefy.png"),
	UPGRADE_BOMBARDMENT: preload("res://Assets/Cards/bombardment.png"),
	UPGRADE_GANG_UP: preload("res://Assets/Cards/gang_up.png"),
	UPGRADE_MUTATE: preload("res://Assets/Cards/mutate.png"),
	UPGRADE_EVOLVE: preload("res://Assets/Cards/evolve.png"),
	UPGRADE_DEVOUR: preload("res://Assets/Cards/devour.png"),
	UPGRADE_MITOCHONDRIA: preload("res://Assets/Cards/mitochondria.png"),
	UPGRADE_ACCELERANT: preload("res://Assets/Cards/accelerant.png")
}

var UPGRADES: Array = [0, 1, 4, 7, 5, 6, 2, 3, 8, 9]
var upgrades: Array = [0, 1, 4, 7, 5, 6, 2, 3, 8, 9]
var button0
var button1
var button2
var cell: CharacterBody2D
var hover_targets: Dictionary = {}
var hover_rest_positions: Dictionary = {}
var hover_rest_scales: Dictionary = {}
var hover_buttons: Array[Button] = []

const MIN_SPLIT_HEALTH := 1
const HOVER_SCALE := Vector2(1.08, 1.08)
const HOVER_LIFT := -12.0
const HOVER_LERP_SPEED := 12.0

func _ready() -> void:
	hover_buttons = [
		$UIRoot/Button0,
		$UIRoot/Button1,
		$UIRoot/Button2
	]
	for button in hover_buttons:
		_connect_hover_signals(button)
		_store_hover_rest_state(button)
		_setup_shine(button)

func _process(delta: float) -> void:
	for button in hover_buttons:
		if button == null or !is_instance_valid(button):
			continue
		var target: Control = _get_hover_target(button)
		if target == null or !is_instance_valid(target):
			continue
		var base_position: Vector2 = hover_rest_positions.get(target, target.position)
		var base_scale: Vector2 = hover_rest_scales.get(target, target.scale)
		var hovered: bool = bool(hover_targets.get(target, false))
		var desired_position: Vector2 = base_position
		var desired_scale: Vector2 = base_scale
		if hovered:
			desired_position = base_position + Vector2(0.0, HOVER_LIFT)
			desired_scale = Vector2(base_scale.x * HOVER_SCALE.x, base_scale.y * HOVER_SCALE.y)
		target.position = target.position.lerp(desired_position, delta * HOVER_LERP_SPEED)
		target.scale = target.scale.lerp(desired_scale, delta * HOVER_LERP_SPEED)

func new_upgrades():
	$UIRoot/Button0.disabled = true
	$UIRoot/Button1.disabled = true
	$UIRoot/Button2.disabled = true
	$UIRoot/DisabledTimer.start()
	upgrades = _build_available_upgrades()
	for i in 3:
		if upgrades.is_empty():
			break
		var type = upgrades.pick_random()
		var button: Button
		
		if i == 0:
			button = $UIRoot/Button0
			button0 = type
		elif i == 1:
			button = $UIRoot/Button1
			button1 = type
		elif i == 2:
			button = $UIRoot/Button2
			button2 = type
		
		_configure_upgrade_button(button, type)
		upgrades.erase(type)
	
	upgrades.clear()
	for i in UPGRADES:
		upgrades.append(UPGRADES[i])

func _configure_upgrade_button(button: Button, upgrade_type: int) -> void:
	var label: Label = button.get_node("UpgradeLabel")
	label.text = UPGRADE_LABELS.get(upgrade_type, "Unknown upgrade")
	var upgrade_icon: Texture2D = UPGRADE_ICONS.get(upgrade_type, null)
	var card_icon: Node = button.get_node_or_null("CardIcon")
	if card_icon is TextureRect:
		card_icon.texture = upgrade_icon
		button.icon = null
	else:
		button.icon = upgrade_icon

func set_cell(cell_: CharacterBody2D):
	cell = cell_

func _on_disabled_timer_timeout() -> void:
	$UIRoot/Button0.disabled = false
	$UIRoot/Button1.disabled = false
	$UIRoot/Button2.disabled = false

func _on_button_0_pressed() -> void:
	_play_confirm_sfx()
	if _apply_upgrade(button0):
		chosen_upgrade.emit()


func _on_button_1_pressed() -> void:
	_play_confirm_sfx()
	if _apply_upgrade(button1):
		chosen_upgrade.emit()


func _on_button_2_pressed() -> void:
	_play_confirm_sfx()
	if _apply_upgrade(button2):
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

func devour() -> bool:
	devour_requested.emit(cell)
	return false

func mitochondria() -> void:
	cell.mutation_effectiveness *= 2.0

func accelerant() -> void:
	cell.poison_effectiveness *= 2.0

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
		
		_setup_new_split_clone(clone, cell_health)
		
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
	
	_setup_new_split_clone(clone, cell.health)
	
	clone.hide()
	
	main.add_child(clone)
	
	clone.add_to_group("cells")

func _build_split_stats(divisor: int) -> Dictionary:
	var split_health: int = max(int(ceil(cell.health / float(divisor))), MIN_SPLIT_HEALTH)
	
	return {
		"health": min(split_health, cell.max_health)
	}

func _setup_new_split_clone(clone: CharacterBody2D, clone_health: int) -> void:
	clone.health = clone_health
	clone.max_health = cell.max_health
	clone.damage = cell.damage
	var clone_attack_timer: Timer = clone.get_node_or_null("AttackTimer")
	var cell_attack_timer: Timer = cell.get_node_or_null("AttackTimer")
	if clone_attack_timer != null and cell_attack_timer != null:
		clone_attack_timer.wait_time = cell_attack_timer.wait_time

func _play_confirm_sfx() -> void:
	var main = get_tree().current_scene
	if main != null and main.has_method("_play_sfx"):
		main._play_sfx("play_ui_click")

func _apply_upgrade(upgrade_id: int) -> bool:
	if upgrade_id == UPGRADE_MITOSIS:
		mitosis()
	elif upgrade_id == UPGRADE_FRACTURE:
		fracture()
	elif upgrade_id == UPGRADE_BEEFY:
		beefy()
	elif upgrade_id == UPGRADE_BOMBARDMENT:
		bombardment()
	elif upgrade_id == UPGRADE_GANG_UP:
		gang_up()
	elif upgrade_id == UPGRADE_MUTATE:
		mutate()
	elif upgrade_id == UPGRADE_EVOLVE:
		evolve()
	elif upgrade_id == UPGRADE_DEVOUR:
		return devour()
	elif upgrade_id == UPGRADE_MITOCHONDRIA:
		mitochondria()
	elif upgrade_id == UPGRADE_ACCELERANT:
		accelerant()
	return true

func mutate() -> void:
	_apply_random_mutation(cell)

func evolve() -> void:
	if cell.has_method("evolve_to_eukaryote"):
		cell.evolve_to_eukaryote()
	_apply_random_mutation(cell)

func _apply_random_mutation(target_cell: CharacterBody2D) -> bool:
	var available_mutations: Array[StringName] = _get_available_mutations(target_cell)
	if available_mutations.is_empty():
		return false
	var mutation_index: int = randi() % available_mutations.size()
	var mutation_id: StringName = available_mutations[mutation_index]
	return _apply_mutation(target_cell, mutation_id)

func _apply_mutation(target_cell: CharacterBody2D, mutation_id: StringName) -> bool:
	if !target_cell.has_method("add_mutation"):
		return false
	var was_added: bool = target_cell.add_mutation(mutation_id)
	if !was_added:
		return false
	return true

func _get_available_mutations(target_cell: CharacterBody2D) -> Array[StringName]:
	var mutation_pool: Array[StringName] = _get_mutation_pool()
	var available_mutations: Array[StringName] = []
	for mutation_id in mutation_pool:
		if target_cell.has_method("has_mutation") and target_cell.has_mutation(mutation_id):
			continue
		if target_cell.has_method("can_receive_mutation") and !target_cell.can_receive_mutation():
			break
		available_mutations.append(mutation_id)
	return available_mutations

func _build_available_upgrades() -> Array:
	var available_upgrades: Array = UPGRADES.duplicate()
	if cell == null:
		return available_upgrades
	if _get_available_mutations(cell).is_empty():
		available_upgrades.erase(UPGRADE_MUTATE)
	if cell.get("cell_stage") == &"eukaryote":
		available_upgrades.erase(UPGRADE_EVOLVE)
	if _get_devour_target() == null:
		available_upgrades.erase(UPGRADE_DEVOUR)
	return available_upgrades

func _get_devour_target() -> CharacterBody2D:
	var candidates: Array[CharacterBody2D] = []
	for ally in get_tree().get_nodes_in_group("cells"):
		if ally == null or !is_instance_valid(ally):
			continue
		if ally == cell:
			continue
		candidates.append(ally)
	if candidates.is_empty():
		return null
	var lowest_health_cell: CharacterBody2D = candidates[0]
	for candidate in candidates:
		if candidate.health < lowest_health_cell.health:
			lowest_health_cell = candidate
	return lowest_health_cell

func _connect_hover_signals(button: Button) -> void:
	button.mouse_entered.connect(func(): _start_hover(button))
	button.mouse_exited.connect(func(): _stop_hover(button))

func _start_hover(button: Button) -> void:
	var target: Control = _get_hover_target(button)
	if target == null:
		return
	_store_hover_rest_state(target)
	hover_targets[target] = true
	_play_shine(button)

func _stop_hover(button: Button) -> void:
	var target: Control = _get_hover_target(button)
	if target == null:
		return
	hover_targets[target] = false

func _get_hover_target(button: Button) -> Control:
	return button

func _store_hover_rest_state(target: Control) -> void:
	if !hover_rest_positions.has(target):
		hover_rest_positions[target] = target.position
	if !hover_rest_scales.has(target):
		hover_rest_scales[target] = target.scale

func _setup_shine(button: Button) -> void:
	var shine: AnimatedSprite2D = button.get_node_or_null("Shine")
	if shine == null:
		return
	shine.visible = false
	shine.stop()
	if !shine.animation_finished.is_connected(_on_shine_animation_finished.bind(shine)):
		shine.animation_finished.connect(_on_shine_animation_finished.bind(shine))

func _play_shine(button: Button) -> void:
	var shine: AnimatedSprite2D = button.get_node_or_null("Shine")
	if shine == null:
		return
	if shine.sprite_frames == null:
		return
	var animation_name: StringName = &"default"
	if !shine.sprite_frames.has_animation(animation_name):
		var animation_names: PackedStringArray = shine.sprite_frames.get_animation_names()
		if animation_names.is_empty():
			return
		animation_name = StringName(animation_names[0])
	shine.visible = true
	shine.stop()
	shine.frame = 0
	shine.play(animation_name)

func _on_shine_animation_finished(shine: AnimatedSprite2D) -> void:
	if shine == null or !is_instance_valid(shine):
		return
	shine.stop()
	shine.visible = false
	shine.frame = 0

func _get_mutation_pool() -> Array[StringName]:
	return [
		MUTATION_REGENERATION,
		MUTATION_VOLATILE,
		MUTATION_INFLUENTIAL,
		MUTATION_CONTAGIOUS,
		MUTATION_TISSUE_REPAIR,
		MUTATION_PARALYSIS
	]
