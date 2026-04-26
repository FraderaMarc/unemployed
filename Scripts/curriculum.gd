extends Control

const SKILL_TREE_SCENE = preload("res://Scenes/skill_tree.tscn")

var skill_tree = null

func _ready() -> void:
	hide()

func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		hide()

func _ensure_skill_tree() -> void:
	if skill_tree == null:
		skill_tree = SKILL_TREE_SCENE.instantiate()
		get_parent().add_child(skill_tree)
		skill_tree.curriculum = self
		skill_tree.name = "skill_tree"

func _on_skill_tree_pressed() -> void:
	_ensure_skill_tree()
	hide()
	skill_tree.show()

func open_skill_tree_from_items() -> void:
	_ensure_skill_tree()
	hide()
	skill_tree.show()
