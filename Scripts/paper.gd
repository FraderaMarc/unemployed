extends Area2D

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player"):
		GameManager.obtain_paper()
		GameManager.add_skillcoin(1)
		queue_free()
