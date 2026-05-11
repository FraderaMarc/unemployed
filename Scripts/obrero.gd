extends Node2D

const OBRERO_DIALOGO = preload("res://assets/Dialogues/Obrero.dialogue")

@onready var player: Node = get_node_or_null("../Player")
@onready var area: Area2D = $Area2D

var dialogue_active: bool = false


func _ready() -> void:
	if not area.body_entered.is_connected(_on_body_entered):
		area.body_entered.connect(_on_body_entered)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player") and body.name != "Player":
		return

	if dialogue_active:
		return

	dialogue_active = true

	if player != null and "can_move" in player:
		player.can_move = false

	DialogueManager.show_dialogue_balloon(OBRERO_DIALOGO, "start")


func _on_dialogue_ended(_resource) -> void:
	if player != null and "can_move" in player:
		player.can_move = true

	dialogue_active = false
