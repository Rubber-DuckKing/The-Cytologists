extends Area2D

var damage: int

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player":
		body.hit(damage)
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()
