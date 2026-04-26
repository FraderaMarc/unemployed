extends Control

const FIRST_SKILL_NAME := "Skill1"

var curriculum: Control = null

var skill_levels: Dictionary = {}
var skill_max_levels: Dictionary = {
	"Skill1": 1,
	"Skill2": 1,
	"Skill2_A": 1,
	"Skill3": 1
}

func _ready() -> void:
	hide()

	for button in _get_all_skill_buttons():
		var skill_id: NodePath = _get_skill_id(button)

		if not skill_levels.has(skill_id):
			skill_levels[skill_id] = 0

		if not button.pressed.is_connected(_on_skill_button_pressed):
			button.pressed.connect(_on_skill_button_pressed.bind(button))

	GameManager.skillcoins_changed.connect(_on_skillcoins_changed)
	_refresh_buttons()

func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		hide()
		curriculum.show()

func _on_skill_button_pressed(button: BaseButton) -> void:
	if not _can_upgrade(button):
		_refresh_buttons()
		return

	if not GameManager.spend_skillcoin(1):
		_refresh_buttons()
		return

	var skill_id: NodePath = _get_skill_id(button)
	skill_levels[skill_id] = skill_levels.get(skill_id, 0) + 1

	if button.name == FIRST_SKILL_NAME and skill_levels[skill_id] >= 1:
		GameManager.first_skill_unlocked = true

	_refresh_buttons()

func _on_skillcoins_changed(_total: int) -> void:
	_refresh_buttons()

func _get_all_skill_buttons() -> Array:
	var result: Array = []
	_collect_skill_buttons(self, result)
	return result

func _collect_skill_buttons(node: Node, result: Array) -> void:
	for child in node.get_children():
		if child is BaseButton:
			result.append(child)
		_collect_skill_buttons(child, result)

func _get_skill_id(button: BaseButton) -> NodePath:
	return get_path_to(button)

func _can_upgrade(button: BaseButton) -> bool:
	if GameManager.skillcoins <= 0:
		return false

	var skill_id: NodePath = _get_skill_id(button)
	var current_level: int = skill_levels.get(skill_id, 0)
	var max_level: int = skill_max_levels.get(button.name, 1)

	if current_level >= max_level:
		return false

	if not _parent_requirement_met(button):
		return false

	return true

func _parent_requirement_met(button: BaseButton) -> bool:
	var parent_node: Node = button.get_parent()

	if not parent_node is BaseButton:
		return true

	var parent_button: BaseButton = parent_node as BaseButton
	var parent_id: NodePath = _get_skill_id(parent_button)

	return skill_levels.get(parent_id, 0) >= 1

func _refresh_buttons() -> void:
	for button in _get_all_skill_buttons():
		var skill_id: NodePath = _get_skill_id(button)
		var current_level: int = skill_levels.get(skill_id, 0)
		var max_level: int = skill_max_levels.get(button.name, 1)

		button.disabled = not _can_upgrade(button)

		if button is Button:
			var text_button: Button = button as Button
			text_button.text = "%s %d/%d" % [button.name, current_level, max_level]
