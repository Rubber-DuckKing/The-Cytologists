extends CharacterBody2D

@export var bombardment_bullet_scene: PackedScene

signal selected_for_upgrade

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

const REGEN_PERCENT := 0.05
const MOVE_ACCELERATION := 0.15
const STOP_FRICTION := 0.25
const TARGET_STOP_DISTANCE := 4.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	main = get_tree().current_scene
	main.connect_cell(self)
	screen_size = get_viewport_rect().size
	screen_size.x -= 65
	screen_size.y -= 65
	$UpgradeButton.hide()

func _process(_delta: float) -> void:
	if can_attack:
		var shortest_dist: float = 100000000.0
		var closest_enemy: Node2D = null
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if shortest_dist > distance(global_position, enemy.global_position):
				shortest_dist = distance(global_position, enemy.global_position)
				closest_enemy = enemy
		if closest_enemy != null and shortest_dist <= 300:
			closest_enemy.hit(get_attack_damage())
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

	main.add_child(bullet)
	main._play_sfx("play_bombardment_launch")
	bullet.find_closest_enemy()
	bullet.add_to_group("bullets")
