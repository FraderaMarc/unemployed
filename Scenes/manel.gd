extends Node2D

const MANEL_DIALOGO1 = preload("res://assets/Dialogues/Manel.dialogue")
const MANEL_DIALOGO2 = preload("res://Scenes/Dialogues/Manel2.dialogue")

@onready var area = $Area2D
@onready var player = $"../Player"

var dialogue_active = false

func _ready() -> void:
	area.body_entered.connect(_on_body_entered)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

func _on_body_entered(body: Node2D) -> void:
	if body.name == "Player" and not dialogue_active:
		dialogue_active = true
		player.can_move = false
		
		if GameManager.llapis:
			DialogueManager.show_dialogue_balloon(MANEL_DIALOGO2, "start")
		else:
			DialogueManager.show_dialogue_balloon(MANEL_DIALOGO1, "start")

func _on_dialogue_ended(_resource) -> void:
	player.can_move = true
	dialogue_active = false
