extends Node2D
@export var enemy_scene: PackedScene

var spawn_points := []
var time: float = 1.0
var max_enemies: int = 5
var health = 40
var damage = 8
var xp_amount = 10

const XP_VARIANCE_MIN := 0.8
const XP_VARIANCE_MAX := 1.25

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE
	$Timer.wait_time = time
	for i in get_children():
		if i is Marker2D:
			spawn_points.append(i)

func _on_timer_timeout() -> void:
	if spawn_points.is_empty():
		$Timer.stop()
		return
	
	var main = get_tree().current_scene
	
	var numb
	var spawn
	numb = randi() % spawn_points.size()
	spawn = spawn_points[numb]
	
	var speed = randf_range(0.5,1.0)
	
	var enemy = enemy_scene.instantiate()
	
	enemy.position = spawn.position
	
	enemy.speed = speed
	
	enemy.health = health
	
	enemy.xp_amount = max(1, int(round(xp_amount * randf_range(XP_VARIANCE_MIN, XP_VARIANCE_MAX))))
	
	enemy.max_health = health
	
	enemy.damage = damage
	
	main.add_child(enemy)
	
	enemy.add_to_group("enemies")
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	if enemies.size() == max_enemies:
		$Timer.stop()
