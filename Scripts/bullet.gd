extends Area2D

var damage: int
var has_hit = false

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	
	if body.name == "Player" or body.name.substr(0,5) == "Clone" or body.name.substr(0,5) == "@Char":
		has_hit = true
		
		body.hit(damage)
		queue_free()

func _on_timer_timeout() -> void:
	queue_free()
