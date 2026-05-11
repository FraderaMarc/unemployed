extends Area2D

const HEAL_AMOUNT: float = 20.0

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("Player") or body.is_in_group("player"):
		GameManager.heal_player(HEAL_AMOUNT)
		queue_free()
