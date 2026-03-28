extends Area2D

var damage
var speed = 10
var closest_enemy

func _process(_delta: float) -> void:
	if !closest_enemy.alive:
		queue_free()
	if closest_enemy != null:
		var input_dir = closest_enemy.global_position - global_position
		global_position += input_dir.normalized() * speed

func find_closest_enemy():
	var shortest_dist = 100000000
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if shortest_dist > distance(global_position, enemy.global_position):
			shortest_dist = distance(global_position, enemy.global_position)
			closest_enemy = enemy

func _on_body_entered(body: Node2D) -> void:
	if body.name.substr(0,5) == "@Rigi" or body.name.substr(0,5) == "Bacte":
		body.hit(damage)
		queue_free()

func distance(pos1: Vector2, pos2: Vector2) -> float:
	return sqrt(pow((pos2.x - pos1.x), 2) + pow((pos2.y - pos2.y), 2))
