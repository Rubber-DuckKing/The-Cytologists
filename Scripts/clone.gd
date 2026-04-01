extends CharacterBody2D

@export var bombardment_bullet_scene: PackedScene

signal selected_for_upgrade
signal enemy_killed(enemy: Node2D)

var main
var speed = 500
var push_force = 80.0
var health = 100
var max_health = 100
var damage = 10
var screen_size: Vector2
var can_attack: bool = true
var has_gang_up: bool = false
var gang_up_multiplier = 1.15
var has_beefy: bool = false
var resistance = 1.2
var has_bombardment: bool = false
var bombardment_bullet_damage = 10
var beefy_level = 0
var bombardment_level = 0
var gang_up_level = 0
var cell_stage: StringName = &"prokaryote"
var mutations: Array[StringName] = []
var status_effects: Dictionary = {}
var mutation_effectiveness: float = 1.0
var poison_effectiveness: float = 1.0
var poison_flash_tween: Tween
var mutation_timers: Dictionary = {}

const REGEN_PERCENT := 0.05
const MOVE_ACCELERATION := 0.15
const STOP_FRICTION := 0.25
const TARGET_STOP_DISTANCE := 4.0
const ATTACK_RANGE := 400.0
const STATUS_POISON: StringName = &"poison"
const STATUS_PARALYSIS: StringName = &"paralysis"
const MUTATION_REGENERATION: StringName = &"regeneration"
const MUTATION_VOLATILE: StringName = &"volatile"
const MUTATION_INFLUENTIAL: StringName = &"influential"
const MUTATION_CONTAGIOUS: StringName = &"contagious"
const MUTATION_TISSUE_REPAIR: StringName = &"tissue_repair"
const MUTATION_PARALYSIS: StringName = &"paralysis"
const POISON_TICK_INTERVAL := 2.0
const VOLATILE_INTERVAL := 5.0
const VOLATILE_RADIUS := 220.0
const VOLATILE_DAMAGE_MULTIPLIER := 0.75
const VOLATILE_KNOCKBACK := 320.0
const INFLUENTIAL_INTERVAL := 6.0
const CONTAGIOUS_INTERVAL := 1.0
const CONTAGIOUS_RADIUS := 220.0
const CONTAGIOUS_CHANCE := 0.35
const TISSUE_REPAIR_RATIO := 0.25
const PARALYSIS_CHANCE := 0.2
const PARALYSIS_DURATION := 5.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	main = get_tree().current_scene
	main.connect_cell(self)
	screen_size = get_viewport_rect().size
	screen_size.x -= 65
	screen_size.y -= 65
	$UpgradeButton.hide()

func _process(_delta: float) -> void:
	_process_status_effects(_delta)
	_process_mutations(_delta)
	if can_attack:
		var shortest_dist: float = 100000000.0
		var closest_enemy: Node2D = null
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if shortest_dist > distance(global_position, enemy.global_position):
				shortest_dist = distance(global_position, enemy.global_position)
				closest_enemy = enemy
		if closest_enemy != null and shortest_dist <= ATTACK_RANGE:
			var dealt_damage: int = get_attack_damage()
			closest_enemy.hit(dealt_damage, self)
			apply_on_hit_effects(closest_enemy, dealt_damage)
			can_attack = false
			$AttackTimer.start()

func _physics_process(_delta: float) -> void:
	var start_clamp = Vector2(65, 65)
	global_position = global_position.clamp(start_clamp, screen_size)
	
	if distance(main.get_node("Player").global_position, global_position) > TARGET_STOP_DISTANCE:
		get_input()
	else:
		velocity = velocity.lerp(Vector2.ZERO, STOP_FRICTION)
	move_and_slide()
	
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * push_force)

func get_input():
	var input_dir = main.get_node("Player").global_position - global_position
	var distance_to_target = input_dir.length()
	var desired_speed = min(distance_to_target * 4.0, speed)
	var desired_velocity = input_dir.normalized() * desired_speed
	velocity = velocity.lerp(desired_velocity, MOVE_ACCELERATION)

func get_attack_damage() -> int:
	if !has_gang_up:
		return int(damage)
	var extra_cells = max(get_tree().get_nodes_in_group("cells").size() - 1, 0)
	var total_multiplier = 1.0 + (extra_cells * (gang_up_multiplier - 1.0))
	return max(int(round(damage * total_multiplier)), int(damage))

func hit(hit_damage: int):
	if !has_beefy:
		health -= hit_damage
	else:
		health -= int(hit_damage / resistance)
	if int(health) <= 0:
		health = 0
		call_deferred("queue_free")
	main.refresh_hud.call_deferred()

func add_mutation(mutation_id: StringName) -> bool:
	if mutation_id == StringName():
		return false
	if has_mutation(mutation_id):
		return false
	if !can_receive_mutation():
		return false
	mutations.append(mutation_id)
	return true

func has_mutation(mutation_id: StringName) -> bool:
	return mutations.has(mutation_id)

func get_all_mutations() -> Array[StringName]:
	return mutations.duplicate()

func can_receive_mutation() -> bool:
	return cell_stage == &"eukaryote" or mutations.is_empty()

func evolve_to_eukaryote() -> void:
	cell_stage = &"eukaryote"

func apply_status(status_id: StringName, stacks: int = 1, duration: float = -1.0, _source: Node = null) -> void:
	if status_id == STATUS_POISON:
		var poison_data: Dictionary = status_effects.get(STATUS_POISON, {
			"stacks": 0,
			"tick_timer": 0.0
		})
		poison_data["stacks"] = max(int(poison_data.get("stacks", 0)), stacks)
		poison_data["tick_timer"] = float(poison_data.get("tick_timer", 0.0))
		status_effects[STATUS_POISON] = poison_data
	elif duration > 0.0:
		status_effects[status_id] = {
			"duration": duration
		}

func clear_status(status_id: StringName) -> void:
	status_effects.erase(status_id)

func on_enemy_killed(_enemy: Node2D) -> void:
	enemy_killed.emit(_enemy)
	if has_mutation(MUTATION_REGENERATION):
		var heal_amount: int = max(int(round(max_health * 0.08 * mutation_effectiveness)), 1)
		health = min(health + heal_amount, max_health)
		main.refresh_hud()

func apply_on_hit_effects(enemy: Node2D, dealt_damage: int) -> void:
	if enemy == null or !is_instance_valid(enemy):
		return
	if has_mutation(MUTATION_TISSUE_REPAIR):
		var heal_amount: int = max(int(round(float(dealt_damage) * TISSUE_REPAIR_RATIO * mutation_effectiveness)), 1)
		health = min(health + heal_amount, max_health)
		main.refresh_hud()
	if has_mutation(MUTATION_PARALYSIS):
		var paralysis_roll: float = randf()
		var paralysis_chance: float = min(PARALYSIS_CHANCE * mutation_effectiveness, 0.9)
		if paralysis_roll <= paralysis_chance and enemy.has_method("apply_status"):
			enemy.apply_status(STATUS_PARALYSIS, 1, PARALYSIS_DURATION, self)
	if has_mutation(MUTATION_CONTAGIOUS) and enemy.has_method("apply_status"):
		enemy.apply_status(STATUS_POISON, _contagious_poison_stacks(), -1.0, self)

func _process_mutations(delta: float) -> void:
	if has_mutation(MUTATION_VOLATILE):
		_tick_mutation_timer(MUTATION_VOLATILE, delta)
		if float(mutation_timers.get(MUTATION_VOLATILE, 0.0)) >= VOLATILE_INTERVAL:
			mutation_timers[MUTATION_VOLATILE] = 0.0
			_trigger_volatile_burst()
	if has_mutation(MUTATION_INFLUENTIAL):
		_tick_mutation_timer(MUTATION_INFLUENTIAL, delta)
		if float(mutation_timers.get(MUTATION_INFLUENTIAL, 0.0)) >= INFLUENTIAL_INTERVAL:
			mutation_timers[MUTATION_INFLUENTIAL] = 0.0
			_spread_mutations_to_ally()
	if has_mutation(MUTATION_CONTAGIOUS):
		_tick_mutation_timer(MUTATION_CONTAGIOUS, delta)
		if float(mutation_timers.get(MUTATION_CONTAGIOUS, 0.0)) >= CONTAGIOUS_INTERVAL:
			mutation_timers[MUTATION_CONTAGIOUS] = 0.0
			_try_contagious_tick()

func _tick_mutation_timer(mutation_id: StringName, delta: float) -> void:
	mutation_timers[mutation_id] = float(mutation_timers.get(mutation_id, 0.0)) + delta

func _trigger_volatile_burst() -> void:
	var burst_damage: int = max(int(round(damage * VOLATILE_DAMAGE_MULTIPLIER * mutation_effectiveness)), 1)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null or !is_instance_valid(enemy):
			continue
		if bool(enemy.get("alive")) == false:
			continue
		var dist_to_enemy: float = distance(global_position, enemy.global_position)
		if dist_to_enemy > VOLATILE_RADIUS:
			continue
		enemy.hit(burst_damage, self)
		if enemy is RigidBody2D:
			var push_direction: Vector2 = (enemy.global_position - global_position).normalized()
			enemy.apply_central_impulse(push_direction * VOLATILE_KNOCKBACK * mutation_effectiveness)

func _spread_mutations_to_ally() -> void:
	var ally: CharacterBody2D = _get_nearby_ally_for_influence()
	if ally == null:
		return
	for mutation_id in get_all_mutations():
		if ally.has_method("has_mutation") and ally.has_mutation(mutation_id):
			continue
		if ally.has_method("add_mutation"):
			var added: bool = ally.add_mutation(mutation_id)
			if !added and !(ally.get("cell_stage") == &"eukaryote"):
				break
	_copy_upgrades_to_ally(ally)

func _try_contagious_tick() -> void:
	var enemy: Node2D = _get_nearby_enemy(CONTAGIOUS_RADIUS)
	if enemy == null:
		return
	if randf() <= CONTAGIOUS_CHANCE and enemy.has_method("apply_status"):
		enemy.apply_status(STATUS_POISON, _contagious_poison_stacks(), -1.0, self)

func _contagious_poison_stacks() -> int:
	return max(int(round(poison_effectiveness)), 1)

func _get_nearby_enemy(search_radius: float) -> Node2D:
	var closest_enemy: Node2D = null
	var shortest_dist: float = search_radius
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null or !is_instance_valid(enemy):
			continue
		if bool(enemy.get("alive")) == false:
			continue
		var dist_to_enemy: float = distance(global_position, enemy.global_position)
		if dist_to_enemy <= shortest_dist:
			shortest_dist = dist_to_enemy
			closest_enemy = enemy
	return closest_enemy

func _get_nearby_ally_for_influence() -> CharacterBody2D:
	var closest_ally: CharacterBody2D = null
	var shortest_dist: float = INF
	for ally in get_tree().get_nodes_in_group("cells"):
		if ally == null or !is_instance_valid(ally):
			continue
		if ally == self:
			continue
		var dist_to_ally: float = distance(global_position, ally.global_position)
		if dist_to_ally < shortest_dist:
			shortest_dist = dist_to_ally
			closest_ally = ally
	return closest_ally

func _copy_upgrades_to_ally(ally: CharacterBody2D) -> void:
	if ally == null or !is_instance_valid(ally):
		return
	if has_beefy:
		ally.has_beefy = true
		ally.beefy_level = max(int(ally.beefy_level), int(beefy_level))
		ally.resistance = max(float(ally.resistance), float(resistance))
		var ally_regen_timer: Timer = ally.get_node_or_null("RegenerateTimer")
		if ally_regen_timer != null and ally_regen_timer.is_stopped():
			ally_regen_timer.start()
	if has_bombardment:
		ally.has_bombardment = true
		ally.bombardment_level = max(int(ally.bombardment_level), int(bombardment_level))
		ally.bombardment_bullet_damage = max(int(ally.bombardment_bullet_damage), int(bombardment_bullet_damage))
		var ally_bombardment_timer: Timer = ally.get_node_or_null("BombardmentTimer")
		if ally_bombardment_timer != null and ally_bombardment_timer.is_stopped():
			ally_bombardment_timer.start()
	if has_gang_up:
		ally.has_gang_up = true
		ally.gang_up_level = max(int(ally.gang_up_level), int(gang_up_level))
		ally.gang_up_multiplier = max(float(ally.gang_up_multiplier), float(gang_up_multiplier))
	ally.mutation_effectiveness = max(float(ally.mutation_effectiveness), float(mutation_effectiveness))
	ally.poison_effectiveness = max(float(ally.poison_effectiveness), float(poison_effectiveness))

func _process_status_effects(delta: float) -> void:
	if !status_effects.has(STATUS_POISON):
		return
	var poison_data: Dictionary = status_effects[STATUS_POISON]
	var poison_stacks: int = int(poison_data.get("stacks", 0))
	if poison_stacks <= 0:
		status_effects.erase(STATUS_POISON)
		_clear_poison_visual()
		return
	poison_data["tick_timer"] = float(poison_data.get("tick_timer", 0.0)) + delta
	if poison_data["tick_timer"] < POISON_TICK_INTERVAL:
		status_effects[STATUS_POISON] = poison_data
		return
	poison_data["tick_timer"] = 0.0
	_flash_poison_visual()
	_apply_direct_damage(1)
	poison_data["stacks"] = poison_stacks - 1
	if int(poison_data["stacks"]) <= 0:
		status_effects.erase(STATUS_POISON)
		_clear_poison_visual()
	else:
		status_effects[STATUS_POISON] = poison_data

func _apply_direct_damage(amount: int) -> void:
	health -= amount
	if int(health) <= 0:
		health = 0
		call_deferred("queue_free")
	main.refresh_hud.call_deferred()

func _flash_poison_visual() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite == null:
		return
	if poison_flash_tween != null:
		poison_flash_tween.kill()
	sprite.modulate = Color(0.75, 0.45, 1.0, 1.0)
	poison_flash_tween = create_tween()
	poison_flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.45)

func _clear_poison_visual() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite == null:
		return
	if poison_flash_tween != null:
		poison_flash_tween.kill()
	sprite.modulate = Color(1, 1, 1, 1)

func distance(pos1: Vector2, pos2: Vector2) -> float:
	return pos1.distance_to(pos2)

func _on_attack_timer_timeout() -> void:
	can_attack = true

func _on_upgrade_button_pressed() -> void:
	selected_for_upgrade.emit(self)

func _on_regenerate_timer_timeout() -> void:
	if int(health) < int(max_health):
		var regen_amount = max(int(round(max_health * REGEN_PERCENT)), 1)
		health = min(health + regen_amount, max_health)
		main.refresh_hud()

func _on_bombardment_timer_timeout() -> void:
	var bullet = bombardment_bullet_scene.instantiate()

	bullet.global_position = global_position
	bullet.damage = max(int(bombardment_bullet_damage), int(damage))
	bullet.source_cell = self

	main.add_child(bullet)
	main._play_sfx("play_bombardment_launch")
	bullet.find_closest_enemy()
	bullet.add_to_group("bullets")
