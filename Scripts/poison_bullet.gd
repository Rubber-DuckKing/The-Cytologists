extends Area2D

var damage: int = 0
var speed: float = 1000.0
var direction: Vector2 = Vector2.ZERO
var lifetime: float = 1.2
var poison_stacks: int = 5
var source_enemy: Node = null
var has_hit: bool = false

const STATUS_POISON: StringName = &"poison"

func _process(delta: float) -> void:
	if has_hit:
		return
	if direction != Vector2.ZERO:
		rotation = direction.angle()
	global_position += direction * speed * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	if body.name == "Player" or body.name.substr(0,5) == "Clone" or body.name.substr(0,5) == "@Char":
		has_hit = true
		body.hit(damage)
		if body.has_method("apply_status"):
			body.apply_status(STATUS_POISON, poison_stacks, -1.0, source_enemy)
		queue_free()
