extends CharacterBody2D

signal main_died

var speed = 10
var push_force = 80.0
var health = 10
var damage = 2
var xp = 0
var next_xp = 30
var xp_multiplier = 1.75
var screen_size: Vector2

func _ready() -> void:
	screen_size = get_viewport_rect().size

func _physics_process(_delta: float) -> void:
	global_position = global_position.clamp(Vector2.ZERO, screen_size)
	
	get_input()
	move_and_slide()
	
	for i in get_slide_collision_count():
		var c = get_slide_collision(i)
		if c.get_collider() is RigidBody2D:
			c.get_collider().apply_central_impulse(-c.get_normal() * push_force)

func get_input():
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		position.x -= speed
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		position.x += speed
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		position.y += speed
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		position.y -= speed

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			var shortest_dist = 100000000
			var closest_enemy
			for enemy in get_tree().get_nodes_in_group("enemies"):
				if shortest_dist > distance(global_position, enemy.global_position):
					shortest_dist = distance(global_position, enemy.global_position)
					closest_enemy = enemy
			if shortest_dist <= 200:
				closest_enemy.hit(damage, self)
				$"../GameUI".get_child(1).text = "XP : " + str(xp) + "/" + str(next_xp)
				if xp >= next_xp:
					next_xp = int(next_xp * xp_multiplier)
					$"../GameUI".get_child(1).text = "XP : " + str(xp) + "/" + str(next_xp)

func hit(hit_damage: int):
	health -= hit_damage
	if health < 0:
		health = 0
		main_died.emit()
	$Health.text = str(health) + "/10"

func distance(pos1: Vector2, pos2: Vector2) -> float:
	return sqrt(pow((pos2.x - pos1.x), 2) + pow((pos2.y - pos2.y), 2))
