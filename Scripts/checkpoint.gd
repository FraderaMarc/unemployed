extends Area2D

@export var spawn_offset: Vector2 = Vector2(24, 0)
@export_node_path("Node2D") var spawn_point_path: NodePath

var activated: bool = false


func _ready() -> void:
	add_to_group("checkpoint")

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return

	activated = true

	var spawn_position: Vector2 = _get_spawn_position()
	SaveManager.save_checkpoint(spawn_position)


func _get_spawn_position() -> Vector2:
	var spawn_point: Node2D = get_node_or_null(spawn_point_path) as Node2D

	if spawn_point != null:
		return spawn_point.global_position

	return global_position + spawn_offset
