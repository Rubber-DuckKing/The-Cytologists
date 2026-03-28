extends CharacterBody2D

@export var bombardment_bullet_scene: PackedScene

signal selected_for_upgrade

var main
var speed = 500
var push_force = 80.0
var health = 10
var max_health = 10
var damage = 2
var screen_size: Vector2
var can_attack: bool = true
var has_gang_up: bool = false
var gang_up_multiplier = 1.15
var has_beefy: bool = false
var resistance = 1.2
var has_bombardment: bool = false
var bombardment_bullet_damage = 2

func _ready() -> void:
	main = get_tree().current_scene
	main.connect_cell(self)
	screen_size = get_viewport_rect().size
	screen_size.x -= 65
	screen_size.y -= 65
	$UpgradeButton.hide()

func _process(_delta: float) -> void:
	if can_attack:
		var shortest_dist = 100000000
		var closest_enemy
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if shortest_dist > distance(global_position, enemy.global_position):
				shortest_dist = distance(global_position, enemy.global_position)
				closest_enemy = enemy
		if shortest_dist <= 300:
			if !has_gang_up:
				closest_enemy.hit(int(damage))
			else:
				closest_enemy.hit(int(get_tree().get_nodes_in_group("cells").size() * gang_up_multiplier))
			can_attack = false
			$AttackTimer.start()

func _physics_process(_delta: float) -> void:
	var start_clamp = Vector2(65, 65)
	global_position = global_position.clamp(start_clamp, screen_size)
	
	if distance(main.get_child(2).global_position, global_position) > 10:
		get_input()
	else:
		velocity = Vector2.ZERO
	move_and_slide()
	
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * push_force)

func get_input():
	var input_dir = main.get_child(2).global_position - global_position
	velocity = input_dir.normalized() * speed

func hit(hit_damage: int):
	if !has_beefy:
		health -= hit_damage
	else:
		health -= int(hit_damage / resistance)
	if int(health) <= 0:
		health = 0
		call_deferred("queue_free")
	$Health.text = str(int(health)) + "/" + str(int(max_health))

func distance(pos1: Vector2, pos2: Vector2) -> float:
	return sqrt(pow((pos2.x - pos1.x), 2) + pow((pos2.y - pos2.y), 2))

func _on_attack_timer_timeout() -> void:
	can_attack = true

func _on_upgrade_button_pressed() -> void:
	selected_for_upgrade.emit(self)

func _on_regenerate_timer_timeout() -> void:
	if int(health) < int(max_health):
		health += 1
		$Health.text = str(int(health)) + "/" + str(int(max_health))

func _on_bombardment_timer_timeout() -> void:
	var bullet = bombardment_bullet_scene.instantiate()
	
	bullet.global_position = global_position
	
	var shortest_dist = 100000000
	var closest_enemy
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if shortest_dist > distance(global_position, enemy.global_position):
			shortest_dist = distance(global_position, enemy.global_position)
			closest_enemy = enemy
	
	bullet.target = closest_enemy
	
	bullet.damage = bombardment_bullet_damage
	
	bullet.find_closest_enemy()
	
	main.add_child(bullet)
	
	bullet.add_to_group("bullets")
