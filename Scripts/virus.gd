extends RigidBody2D

@onready var player = get_node_or_null("/root/Main/Player")

@export var bullet_scene: PackedScene

var speed
var height
var direction: Vector2
var target: Vector2
var moving: bool = true
var moving_back: bool = false
var can_attack = true
var alive: bool = true
var damage: int
var health: int
var max_health: int
var xp_amount: int
var screen_size: Vector2
var status_effects: Dictionary = {}
var last_hit_source: Node = null
var poison_flash_tween: Tween

const STATUS_POISON: StringName = &"poison"
const STATUS_PARALYSIS: StringName = &"paralysis"
const POISON_TICK_INTERVAL := 2.0
const SHOT_COUNT := 5
const SPREAD_ANGLE_DEGREES := 28.0
const BULLET_SPEED := 1100.0
const BULLET_DAMAGE := 2
const BULLET_POISON_STACKS := 5

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	$Health.text = str(health) + "/" + str(max_health)
	screen_size = get_viewport_rect().size
	screen_size.x -= 65
	screen_size.y -= 65

func _physics_process(delta: float) -> void:
	if alive:
		_process_status_effects(delta)
		if player == null or !is_instance_valid(player):
			player = get_node_or_null("/root/Main/Player")
			if player == null:
				return
		
		var start_clamp = Vector2(65, 65)
		
		direction = player.global_position - global_position
		direction.normalized()
		
		global_position = global_position.clamp(start_clamp, screen_size)
		if _is_paralyzed():
			return
		
		if moving:
			global_position.x += direction.x * delta * speed
			global_position.y += direction.y * delta * speed
		if moving_back:
			global_position.x -= direction.x * delta * speed
			global_position.y -= direction.y * delta * speed
			if global_position.x <= (65 * 2):
				global_position.x += 10 * delta * speed
			elif global_position.x >= (3000 - (65 * 2)):
				global_position.x -= 10 * delta * speed
		
		if can_attack:
			var shortest_dist = 100000000
			for cell in get_tree().get_nodes_in_group("cells"):
				if shortest_dist > distance(global_position, cell.global_position):
					shortest_dist = distance(global_position, cell.global_position)
			if shortest_dist <= 300:
				attack()
		
func attack():
	var main = get_tree().current_scene
	if player == null or !is_instance_valid(player):
		return
	
	can_attack = false
	target = player.global_position
	main._play_sfx("play_enemy_shot")
	_fire_spread(target)
	$AttackTimer.start()
	moving_back = true
	$MoveBackTimer.start()

func distance(pos1: Vector2, pos2: Vector2) -> float:
	return sqrt(pow((pos2.x - pos1.x), 2) + pow((pos2.y - pos1.y), 2))

func hit(hit_damage: int, source_cell: Node = null):
	var main = get_tree().current_scene
	if source_cell != null and is_instance_valid(source_cell):
		last_hit_source = source_cell
	health -= hit_damage
	if health <= 0:
		health = 0
		hide()
		if alive:
			var killer: Node = source_cell if source_cell != null and is_instance_valid(source_cell) else last_hit_source
			main.add_xp(int(xp_amount))
			main._play_sfx("play_enemy_death")
			if killer != null and is_instance_valid(killer) and killer.has_method("on_enemy_killed"):
				killer.on_enemy_killed(self)
		alive = false
		$CollisionShape2D2.set_deferred("disabled", true)
	else:
		main._play_sfx("play_enemy_hit")
	$Health.text = str(int(health)) + "/" + str(int(max_health))

func _on_attack_timer_timeout() -> void:
	can_attack = true

func _on_move_back_timer_timeout() -> void:
	moving_back = false

func apply_status(status_id: StringName, stacks: int = 1, duration: float = -1.0, source: Node = null) -> void:
	if source != null and is_instance_valid(source):
		last_hit_source = source
	if status_id == STATUS_POISON:
		var poison_data: Dictionary = status_effects.get(STATUS_POISON, {
			"stacks": 0,
			"tick_timer": 0.0
		})
		poison_data["stacks"] = max(int(poison_data.get("stacks", 0)), stacks)
		poison_data["tick_timer"] = float(poison_data.get("tick_timer", 0.0))
		status_effects[STATUS_POISON] = poison_data
	elif status_id == STATUS_PARALYSIS:
		var paralysis_data: Dictionary = status_effects.get(STATUS_PARALYSIS, {
			"duration": 0.0
		})
		paralysis_data["duration"] = max(float(paralysis_data.get("duration", 0.0)), duration)
		status_effects[STATUS_PARALYSIS] = paralysis_data
	elif duration > 0.0:
		status_effects[status_id] = {
			"duration": duration
		}

func clear_status(status_id: StringName) -> void:
	status_effects.erase(status_id)

func _process_status_effects(delta: float) -> void:
	if status_effects.has(STATUS_POISON):
		var poison_data: Dictionary = status_effects[STATUS_POISON]
		var poison_stacks: int = int(poison_data.get("stacks", 0))
		if poison_stacks <= 0:
			status_effects.erase(STATUS_POISON)
		else:
			poison_data["tick_timer"] = float(poison_data.get("tick_timer", 0.0)) + delta
			if poison_data["tick_timer"] >= POISON_TICK_INTERVAL:
				poison_data["tick_timer"] = 0.0
				_flash_poison_visual()
				hit(1, last_hit_source)
				poison_data["stacks"] = poison_stacks - 1
			if int(poison_data.get("stacks", 0)) <= 0:
				status_effects.erase(STATUS_POISON)
				_clear_poison_visual()
			else:
				status_effects[STATUS_POISON] = poison_data
	if status_effects.has(STATUS_PARALYSIS):
		var paralysis_data: Dictionary = status_effects[STATUS_PARALYSIS]
		paralysis_data["duration"] = float(paralysis_data.get("duration", 0.0)) - delta
		if float(paralysis_data["duration"]) <= 0.0:
			status_effects.erase(STATUS_PARALYSIS)
		else:
			status_effects[STATUS_PARALYSIS] = paralysis_data

func _is_paralyzed() -> bool:
	return status_effects.has(STATUS_PARALYSIS)

func _flash_poison_visual() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite == null:
		return
	if poison_flash_tween != null:
		poison_flash_tween.kill()
	sprite.modulate = Color(0.75, 0.45, 1.0, 1.0)
	poison_flash_tween = create_tween()
	poison_flash_tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.35)

func _clear_poison_visual() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite == null:
		return
	if poison_flash_tween != null:
		poison_flash_tween.kill()
	sprite.modulate = Color(1, 1, 1, 1)

func _fire_spread(target_position: Vector2) -> void:
	if bullet_scene == null:
		return
	var main = get_tree().current_scene
	var aim_direction: Vector2 = (target_position - global_position).normalized()
	if aim_direction == Vector2.ZERO:
		aim_direction = Vector2.RIGHT
	var angle_step: float = 0.0
	if SHOT_COUNT > 1:
		angle_step = deg_to_rad(SPREAD_ANGLE_DEGREES / float(SHOT_COUNT - 1))
	var start_angle: float = -deg_to_rad(SPREAD_ANGLE_DEGREES) * 0.5
	for shot_index in SHOT_COUNT:
		var poison_bullet: Area2D = bullet_scene.instantiate()
		var shot_angle: float = start_angle + (angle_step * float(shot_index))
		var shot_direction: Vector2 = aim_direction.rotated(shot_angle)
		poison_bullet.global_position = global_position
		poison_bullet.damage = BULLET_DAMAGE
		poison_bullet.source_enemy = self
		poison_bullet.direction = shot_direction
		poison_bullet.speed = BULLET_SPEED
		poison_bullet.poison_stacks = BULLET_POISON_STACKS
		main.add_child(poison_bullet)
		poison_bullet.add_to_group("bullets")
