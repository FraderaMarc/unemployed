extends Node2D

const OBRERO_DIALOGO = preload("res://assets/Dialogues/Obrero.dialogue")

@onready var player = $"../Player"
@onready var area = $Area2D

var dialogue_active: bool = false

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)

	if not DialogueManager.dialogue_ended.is_connected(_on_dialogue_ended):
		DialogueManager.dialogue_ended.connect(_on_dialogue_ended)


func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not dialogue_active:
		dialogue_active = true
		player.can_move = false
		DialogueManager.show_dialogue_balloon(OBRERO_DIALOGO, "start")


func _on_dialogue_ended(_resource) -> void:
	player.can_move = true
	dialogue_active = false
