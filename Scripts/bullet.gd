extends Area2D

var damage: int
var has_hit: bool = false
var source_enemy: Node = null
var inflicted_statuses: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func arm() -> void:
	var collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D")
	var despawn_timer: Timer = get_node_or_null("DespawnTimer")
	if collision_shape != null:
		collision_shape.disabled = false
	
	# If a body is already inside the blast when the bullet arms, body_entered may
	# not fire, so apply the hit immediately.
	for body in get_overlapping_bodies():
		_try_hit_body(body)
		if has_hit:
			return
	
	if despawn_timer != null and despawn_timer.is_stopped():
		despawn_timer.start()

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	
	_try_hit_body(body)

func _try_hit_body(body: Node2D) -> void:
	if has_hit:
		return
	
	if body.name == "Player" or body.name.substr(0,5) == "Clone" or body.name.substr(0,5) == "@Char":
		has_hit = true
		
		body.hit(damage)
		_apply_status_payload(body)
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()

func add_inflicted_status(status_id: StringName, stacks: int = 1, duration: float = -1.0) -> void:
	inflicted_statuses[status_id] = {
		"stacks": stacks,
		"duration": duration
	}

func _apply_status_payload(body: Node2D) -> void:
	if inflicted_statuses.is_empty():
		return
	if !body.has_method("apply_status"):
		return
	for status_id_variant in inflicted_statuses.keys():
		var status_id: StringName = StringName(status_id_variant)
		var status_data: Dictionary = inflicted_statuses[status_id]
		var stacks: int = int(status_data.get("stacks", 1))
		var duration: float = float(status_data.get("duration", -1.0))
		body.apply_status(status_id, stacks, duration, source_enemy)
