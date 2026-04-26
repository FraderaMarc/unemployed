extends Node2D

var item_scene := preload("res://Scenes/Llapis.tscn")

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		body.velocity.y=-400
		drop_item()
		queue_free()

func drop_item() -> void:
	var item = item_scene.instantiate()
	item.global_position = global_position
	get_parent().add_child(item)

func _on_area_2d_2_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		get_tree().reload_current_scene()
