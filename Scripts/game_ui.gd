extends CanvasLayer

@onready var xp_bar: ProgressBar = $TopMargin/XPPanel/XPBar
@onready var level_label: Label = $TopMargin/XPPanel/XPBar/LevelLabel
@onready var xp_value_label: Label = $TopMargin/XPPanel/XPBar/XPValueLabel
@onready var hp_bars: VBoxContainer = $LeftMargin/HPBars
@onready var cell_bar_template: PanelContainer = $CellBarTemplate
@onready var attack_bar: ProgressBar = $BottomLeftMargin/AttackPanel/AttackContent/AttackBar
@onready var attack_label: Label = $BottomLeftMargin/AttackPanel/AttackContent/AttackLabel

@export var player_icon: Texture2D
@export var clone_icon: Texture2D

var cell_bar_map: Dictionary = {}
var clone_label_numbers: Dictionary = {}

func update_xp_display(current_xp: int, next_xp: int, current_level: int) -> void:
	xp_bar.max_value = max(next_xp, 1)
	xp_bar.value = clamp(current_xp, 0, next_xp)
	level_label.text = "LEVEL " + str(current_level)
	xp_value_label.text = str(current_xp) + " / " + str(next_xp)

func refresh_cell_bars(cells: Array) -> void:
	var active_ids: Dictionary = {}
	var ordered_cells: Array = cells.duplicate()
	ordered_cells.sort_custom(_sort_cells)

	for cell in ordered_cells:
		if cell == null:
			continue

		var cell_id: int = cell.get_instance_id()
		active_ids[cell_id] = true
		if cell.name != "Player" and !clone_label_numbers.has(cell_id):
			clone_label_numbers[cell_id] = _next_available_clone_number()

		var bar: PanelContainer = cell_bar_map.get(cell_id, null)
		if bar == null:
			bar = cell_bar_template.duplicate()
			bar.visible = true
			hp_bars.add_child(bar)
			cell_bar_map[cell_id] = bar

		_update_cell_bar(bar, cell)

	for cell_id in cell_bar_map.keys():
		if active_ids.has(cell_id):
			continue
		var old_bar: PanelContainer = cell_bar_map[cell_id]
		if is_instance_valid(old_bar):
			old_bar.queue_free()
		cell_bar_map.erase(cell_id)
		clone_label_numbers.erase(cell_id)

func clear_cell_bars() -> void:
	for cell_id in cell_bar_map.keys():
		var bar: PanelContainer = cell_bar_map[cell_id]
		if is_instance_valid(bar):
			bar.queue_free()
	cell_bar_map.clear()
	clone_label_numbers.clear()

func update_attack_bar(time_left: float, wait_time: float, can_attack: bool) -> void:
	attack_bar.max_value = max(wait_time, 0.001)
	if can_attack:
		attack_bar.value = attack_bar.max_value
		attack_label.text = "ATTACK READY"
	else:
		attack_bar.value = clamp(wait_time - time_left, 0.0, attack_bar.max_value)
		attack_label.text = "ATTACK CHARGING"

func _update_cell_bar(bar: PanelContainer, cell: CharacterBody2D) -> void:
	var cell_name: Label = bar.get_node("Margin/Row/Content/CellName")
	var health_bar: ProgressBar = bar.get_node("Margin/Row/Content/HealthBar")
	var icon: TextureRect = bar.get_node("Margin/Row/Icon")

	cell_name.text = _display_name_for_cell(cell)

	var max_hp = max(float(cell.max_health), 1.0)
	var hp = clamp(float(cell.health), 0.0, max_hp)
	var ratio = hp / max_hp

	health_bar.max_value = max_hp
	health_bar.value = hp

	var fill_style := health_bar.get_theme_stylebox("fill")
	if fill_style is StyleBoxFlat:
		var new_fill := fill_style.duplicate()
		new_fill.bg_color = _health_color_for_ratio(ratio)
		health_bar.add_theme_stylebox_override("fill", new_fill)

	icon.texture = _icon_for_cell(cell)

func _display_name_for_cell(cell: CharacterBody2D) -> String:
	if cell.name == "Player":
		return "MAIN CELL"
	var cell_id: int = cell.get_instance_id()
	if !clone_label_numbers.has(cell_id):
		clone_label_numbers[cell_id] = _next_available_clone_number()
	return "CLONE CELL " + str(clone_label_numbers[cell_id])

func get_display_name_for_cell(cell: CharacterBody2D) -> String:
	return _display_name_for_cell(cell)

func _sort_cells(a: CharacterBody2D, b: CharacterBody2D) -> bool:
	if a.name == "Player":
		return true
	if b.name == "Player":
		return false
	return _clone_number_for_cell(a) < _clone_number_for_cell(b)

func _health_color_for_ratio(ratio: float) -> Color:
	if ratio <= 0.25:
		return Color(0.86, 0.2, 0.2, 1.0)
	elif ratio <= 0.5:
		return Color(0.95, 0.8, 0.2, 1.0)
	return Color(0.4, 0.9, 0.25, 1.0)

func _icon_for_cell(cell: CharacterBody2D) -> Texture2D:
	if cell.name == "Player":
		return player_icon
	return clone_icon

func _clone_number_for_cell(cell: CharacterBody2D) -> int:
	var cell_id: int = cell.get_instance_id()
	if !clone_label_numbers.has(cell_id):
		clone_label_numbers[cell_id] = _next_available_clone_number()
	return clone_label_numbers[cell_id]

func _next_available_clone_number() -> int:
	var number := 1
	while clone_label_numbers.values().has(number):
		number += 1
	return number
