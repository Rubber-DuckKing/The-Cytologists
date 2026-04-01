extends Area2D

var damage: int
var speed: float = 10.0
var closest_enemy
var source_cell: Node = null

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
	var move_direction: Vector2 = input_dir.normalized()
	if move_direction != Vector2.ZERO:
		rotation = move_direction.angle()
	global_position += move_direction * speed

func find_closest_enemy():
	closest_enemy = null
	var shortest_dist: float = INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null or !is_instance_valid(enemy):
			continue
		if _enemy_is_dead(enemy):
			continue
		var dist: float = distance(global_position, enemy.global_position)
		if shortest_dist > dist:
			shortest_dist = dist
			closest_enemy = enemy

func _on_body_entered(body: Node2D) -> void:
	if body.name.substr(0,5) == "@Rigi" or body.name.substr(0,5) == "Bacte":
		body.hit(damage, source_cell)
		if source_cell != null and is_instance_valid(source_cell) and source_cell.has_method("apply_on_hit_effects"):
			source_cell.apply_on_hit_effects(body, damage)
		queue_free()

func distance(pos1: Vector2, pos2: Vector2) -> float:
	return sqrt(pow((pos2.x - pos1.x), 2) + pow((pos2.y - pos1.y), 2))

func _enemy_is_dead(enemy) -> bool:
	if enemy == null or !is_instance_valid(enemy):
		return true
	return bool(enemy.get("alive")) == false
