extends Node2D

const MERCEDES_DIALOGO = preload("res://assets/Dialogues/Mercedes.dialogue")
const INUTIL_DIALOGO = preload("res://assets/Dialogues/Inutil.dialogue")

@onready var player = $"../Player"
@onready var area = $Area2D

var dialogue_active = false

func _ready():
	area.body_entered.connect(_on_body_entered)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

	dialogue_active = true
	player.can_move = false
	DialogueManager.show_dialogue_balloon(MERCEDES_DIALOGO, "start")

func _on_body_entered(body):
	if body.name == "Player" and not dialogue_active:
		dialogue_active = true
		player.can_move = false
		DialogueManager.show_dialogue_balloon(INUTIL_DIALOGO, "start")

func _on_dialogue_ended(_resource):
	player.can_move = true
	dialogue_active = false
