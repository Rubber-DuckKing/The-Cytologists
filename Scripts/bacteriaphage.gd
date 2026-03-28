extends RigidBody2D

@onready var player = get_node("/root/Main/Player")

@export var bullet_scene: PackedScene

var speed
var height
var direction: Vector2
var target: Vector2
var start_pos: Vector2
var moving: bool = true
var moving_back: bool = false
var attacking: bool = false
var can_attack = true
var alive: bool = true
var lambda: float = 0.01
var damage: int
var health: int
var max_health: int
var xp_amount: int
var bullet
var screen_size: Vector2

func _ready() -> void:
	$Health.text = str(health) + "/" + str(max_health)
	screen_size = get_viewport_rect().size
	screen_size.x -= 65
	screen_size.y -= 65

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	if alive:
		var start_clamp = Vector2(65, 65)
		
		direction = player.global_position - global_position
		direction.normalized()
		
		global_position = global_position.clamp(start_clamp, screen_size)
		
		if moving:
			global_position.x += direction.x * delta * speed
			global_position.y += direction.y * delta * speed
		if attacking:
			move_bullet()
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
		
		if lambda >= 1:
			lambda = 0.01
			attacking = false
			moving = true
			$AttackTimer.start()
		elif lambda < 1 and attacking:
			lambda += 0.01
	#(1−𝜆)𝐴+𝜆𝐵+4𝐶𝐷𝜆(1−𝜆)

func attack():
	var main = get_tree().current_scene
	
	moving = false
	can_attack = false
	
	target = player.global_position
	start_pos = global_position
	
	height = -300

	bullet = bullet_scene.instantiate()
	
	attacking = true
	
	move_bullet()
	bullet.add_to_group("bullets")
	main.add_child(bullet)
	
	moving_back = true
	$MoveBackTimer.start()

func move_bullet():
	bullet.global_position.x = ((1-lambda)*start_pos.x) + (lambda * target.x) + (4 * -height * lambda * (1 - lambda))
	bullet.global_position.y = ((1-lambda)*start_pos.y) + (lambda * target.y) + (4 * height * lambda * (1 - lambda))
	if bullet.global_position.x == target.x and bullet.global_position.y == target.y:
		bullet.damage = int(damage)
		bullet.get_child(0).disabled = false
		bullet.get_child(2).start()

func distance(pos1: Vector2, pos2: Vector2) -> float:
	return sqrt(pow((pos2.x - pos1.x), 2) + pow((pos2.y - pos1.y), 2))

func hit(hit_damage: int):
	var main = get_tree().current_scene
	health -= hit_damage
	if health <= 0:
		health = 0
		hide()
		if alive:
			main.add_xp(int(xp_amount))
		alive = false
		$CollisionShape2D2.disabled = true
		if bullet != null:
			bullet.queue_free()
	$Health.text = str(int(health)) + "/" + str(int(max_health))

func _on_attack_timer_timeout() -> void:
	can_attack = true

func _on_move_back_timer_timeout() -> void:
	moving_back = false
