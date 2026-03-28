extends Node2D
@export var enemy_scene: PackedScene

var spawn_points := []
var time: float = 1.0
var max_enemies: int = 5
var health = 5
var damage = 2
var xp_amount = 10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Timer.wait_time = time
	for i in get_children():
		if i is Marker2D:
			spawn_points.append(i)

func _on_timer_timeout() -> void:
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
	
	enemy.xp_amount = xp_amount
	
	enemy.max_health = health
	
	enemy.damage = damage
	
	main.add_child(enemy)
	
	enemy.add_to_group("enemies")
	
	var enemies = get_tree().get_nodes_in_group("enemies")
	
	if enemies.size() == max_enemies:
		$Timer.stop()
