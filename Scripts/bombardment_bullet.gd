extends Area2D

var damage: int
var speed: float = 10.0
var closest_enemy

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(_delta: float) -> void:
	if closest_enemy == null or !is_instance_valid(closest_enemy):
		find_closest_enemy()
		if closest_enemy == null:
			queue_free()
			return
	
	if _enemy_is_dead(closest_enemy):
		find_closest_enemy()
		if closest_enemy == null:
			queue_free()
			return
	
	var input_dir = closest_enemy.global_position - global_position
	global_position += input_dir.normalized() * speed

func find_closest_enemy():
	closest_enemy = null
	var shortest_dist: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null or !is_instance_valid(enemy):
			continue
		if _enemy_is_dead(enemy):
			continue
		var dist := distance(global_position, enemy.global_position)
		if shortest_dist > dist:
			shortest_dist = dist
			closest_enemy = enemy

func _on_body_entered(body: Node2D) -> void:
	if body.name.substr(0,5) == "@Rigi" or body.name.substr(0,5) == "Bacte":
		body.hit(damage)
		queue_free()

func distance(pos1: Vector2, pos2: Vector2) -> float:
	return sqrt(pow((pos2.x - pos1.x), 2) + pow((pos2.y - pos1.y), 2))

func _enemy_is_dead(enemy) -> bool:
	if enemy == null or !is_instance_valid(enemy):
		return true
	return bool(enemy.get("alive")) == false
