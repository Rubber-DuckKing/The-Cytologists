extends Area2D

var damage: int
var has_hit = false

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
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()
