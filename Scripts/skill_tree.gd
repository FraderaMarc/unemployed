extends Control

const FIRST_SKILL_NAME := "Skill1"
const DIRECTOREO_GIF_PATH: String = "res://GifMarcos.gif"

const SKILL2_HEALTH_INCREASE: float = 15.0
const SKILL2_A_DAMAGE_INCREASE: float = 3.0
const SKILL3_RESISTANCE_INCREASE: float = 3.0

const ESCUDO1_RESISTANCE_INCREASE: float = 5.0
const ESCUDO2_RESISTANCE_INCREASE: float = 7.0

const VIDA1_HEALTH_INCREASE: float = 17.0
const VIDA2_HEALTH_INCREASE: float = 21.0
const VIDA3_HEALTH_INCREASE: float = 19.0

const DANO1_DAMAGE_INCREASE: float = 6.0
const DANO2_DAMAGE_INCREASE: float = 9.0
const DANO3_DAMAGE_INCREASE: float = 15.0

var curriculum: Control = null

var skill_max_levels: Dictionary = {
	"Skill1": 1,
	"Skill2": 1,
	"Skill2_A": 3,
	"Skill3": 3,
	"Escudo1": 3,
	"Escudo2": 3,
	"Daño1": 3,
	"Daño2": 3,
	"Daño3": 3,
	"Vida1": 3,
	"Vida2": 3,
	"Vida3": 3
}


func _ready() -> void:
	hide()

	for button in _get_all_skill_buttons():
		var skill_id: String = _get_skill_id(button)

		if not GameManager.skill_levels.has(skill_id):
			GameManager.skill_levels[skill_id] = 0

		if not button.pressed.is_connected(_on_skill_button_pressed):
			button.pressed.connect(_on_skill_button_pressed.bind(button))

	if not GameManager.skillcoins_changed.is_connected(_on_skillcoins_changed):
		GameManager.skillcoins_changed.connect(_on_skillcoins_changed)

	_refresh_buttons()

	if GameManager.is_mission_completed("completa_curriculum"):
		call_deferred("_show_directoreo_overlay")


func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		hide()

		if curriculum != null:
			curriculum.show()


func _on_skill_button_pressed(button: BaseButton) -> void:
	if not _can_upgrade(button):
		_refresh_buttons()
		return

	if not GameManager.spend_skillcoin(1):
		_refresh_buttons()
		return

	var skill_id: String = _get_skill_id(button)
	GameManager.skill_levels[skill_id] = int(GameManager.skill_levels.get(skill_id, 0)) + 1

	_apply_skill_effect(button.name)

	if button.name == FIRST_SKILL_NAME and int(GameManager.skill_levels.get(skill_id, 0)) >= 1:
		GameManager.unlock_first_skill()

	_refresh_buttons()
	_complete_curriculum_mission_if_needed()


func _apply_skill_effect(skill_name: String) -> void:
	match skill_name:
		"Skill1":
			pass

		"Skill2":
			GameManager.increase_max_health(SKILL2_HEALTH_INCREASE)

		"Skill2_A":
			GameManager.increase_attack_damage(SKILL2_A_DAMAGE_INCREASE)

		"Skill3":
			GameManager.increase_max_resistance(SKILL3_RESISTANCE_INCREASE)

		"Escudo1":
			GameManager.increase_max_resistance(ESCUDO1_RESISTANCE_INCREASE)

		"Escudo2":
			GameManager.increase_max_resistance(ESCUDO2_RESISTANCE_INCREASE)

		"Vida1":
			GameManager.increase_max_health(VIDA1_HEALTH_INCREASE)

		"Vida2":
			GameManager.increase_max_health(VIDA2_HEALTH_INCREASE)

		"Vida3":
			GameManager.increase_max_health(VIDA3_HEALTH_INCREASE)

		"Daño1":
			GameManager.increase_attack_damage(DANO1_DAMAGE_INCREASE)

		"Daño2":
			GameManager.increase_attack_damage(DANO2_DAMAGE_INCREASE)

		"Daño3":
			GameManager.increase_attack_damage(DANO3_DAMAGE_INCREASE)


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


func _get_skill_id(button: BaseButton) -> String:
	return str(get_path_to(button))


func _can_upgrade(button: BaseButton) -> bool:
	if GameManager.skillcoins <= 0:
		return false

	var skill_id: String = _get_skill_id(button)
	var current_level: int = int(GameManager.skill_levels.get(skill_id, 0))
	var max_level: int = int(skill_max_levels.get(button.name, 1))

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
	var parent_id: String = _get_skill_id(parent_button)

	return int(GameManager.skill_levels.get(parent_id, 0)) >= 1


func _refresh_buttons() -> void:
	for button in _get_all_skill_buttons():
		var skill_id: String = _get_skill_id(button)
		var current_level: int = int(GameManager.skill_levels.get(skill_id, 0))
		var max_level: int = int(skill_max_levels.get(button.name, 1))

		button.disabled = not _can_upgrade(button)

		if button.has_method("set_level_text"):
			button.set_level_text(current_level, max_level)

		if button.has_method("set_unlocked_visual"):
			button.set_unlocked_visual(current_level > 0)


func _is_skill_tree_completed() -> bool:
	for button in _get_all_skill_buttons():
		var skill_id: String = _get_skill_id(button)
		var current_level: int = int(GameManager.skill_levels.get(skill_id, 0))
		var max_level: int = int(skill_max_levels.get(button.name, 1))

		if current_level < max_level:
			return false

	return true


func _complete_curriculum_mission_if_needed() -> void:
	if not _is_skill_tree_completed():
		return

	if GameManager.has_mission("completa_curriculum") and not GameManager.is_mission_completed("completa_curriculum"):
		GameManager.complete_mission("completa_curriculum")

	_show_directoreo_overlay()


func _show_directoreo_overlay() -> void:
	var overlay_parent: Node = get_node_or_null("/root/Map/CanvasLayer")

	if overlay_parent == null:
		overlay_parent = get_tree().current_scene

	if overlay_parent == null:
		return

	if overlay_parent.has_node("DirectoreoOverlay"):
		return

	if not ResourceLoader.exists(DIRECTOREO_GIF_PATH):
		push_warning("No existe el GIF del directoreo: " + DIRECTOREO_GIF_PATH)
		return

	var gif_texture: Resource = load(DIRECTOREO_GIF_PATH)

	if gif_texture == null:
		push_warning("No se ha podido cargar el GIF: " + DIRECTOREO_GIF_PATH)
		return

	var overlay: Control = Control.new()
	overlay.name = "DirectoreoOverlay"
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.z_index = 9999
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)

	var texture_rect: TextureRect = TextureRect.new()
	texture_rect.name = "GifMarcos"
	texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	if gif_texture is Texture2D:
		texture_rect.texture = gif_texture as Texture2D
	else:
		push_warning("GifMarcos.gif no se ha cargado como Texture2D.")
		return

	overlay.add_child(texture_rect)
	overlay_parent.add_child(overlay)
