extends Control

const SKILL_TREE_SCENE: PackedScene = preload("res://Scenes/skill_tree.tscn")

const ICON_VIDA_PATH: String = "res://assets/Idle/UI/IconHeart.png"
const ICON_VELOCIDAD_PATH: String = "res://assets/Idle/UI/IconSpeed.png"
const ICON_RESISTENCIA_PATH: String = "res://assets/Idle/UI/IconStamina.png"
const ICON_FUERZA_PATH: String = "res://assets/Idle/UI/IconStrength.png"

@onready var panel: Panel = $Panel
@onready var missions_button: TextureButton = $Panel/Missiones
@onready var stats_button: TextureButton = $Panel/Stats

var skill_tree: Control = null

var missions_panel: Panel = null
var missions_container: VBoxContainer = null
var mission_button_label: Label = null
var mission_popup: Panel = null
var mission_popup_timer: Timer = null
var mission_popup_label: Label = null

var stats_panel: Panel = null
var stats_container: VBoxContainer = null

func _ready() -> void:
	hide()

	_create_mission_button_label()
	_create_mission_popup()
	_create_stats_display()

	if not missions_button.pressed.is_connected(_on_missiones_pressed):
		missions_button.pressed.connect(_on_missiones_pressed)

	if not GameManager.mission_started.is_connected(_on_mission_started):
		GameManager.mission_started.connect(_on_mission_started)

	if not GameManager.missions_changed.is_connected(_refresh_missions_ui):
		GameManager.missions_changed.connect(_refresh_missions_ui)

	if not GameManager.player_stats_changed.is_connected(_refresh_stats_display):
		GameManager.player_stats_changed.connect(_refresh_stats_display)

	_refresh_missions_ui()
	_refresh_stats_display()

func _process(_delta: float) -> void:
	if visible and Input.is_action_just_pressed("ui_cancel"):
		if missions_panel != null and missions_panel.visible:
			missions_panel.hide()
		else:
			hide()

# -------------------------
# SKILL TREE
# -------------------------

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

# -------------------------
# BOTÓN DE MISIONES
# -------------------------

func _on_missiones_pressed() -> void:
	_ensure_missions_panel()
	missions_panel.visible = not missions_panel.visible
	missions_button.button_pressed = false
	_refresh_missions_ui()

func _create_mission_button_label() -> void:
	mission_button_label = Label.new()
	mission_button_label.name = "MissionButtonLabel"
	mission_button_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mission_button_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	mission_button_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	mission_button_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_button_label.clip_text = true
	mission_button_label.text = "Misiones"

	mission_button_label.add_theme_color_override("font_color", Color.WHITE)
	mission_button_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	mission_button_label.add_theme_constant_override("shadow_offset_x", 2)
	mission_button_label.add_theme_constant_override("shadow_offset_y", 2)
	mission_button_label.add_theme_font_size_override("font_size", 16)

	missions_button.add_child(mission_button_label)
	mission_button_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	mission_button_label.offset_left = 8
	mission_button_label.offset_top = 8
	mission_button_label.offset_right = -8
	mission_button_label.offset_bottom = -8

func _create_mission_popup() -> void:
	mission_popup = Panel.new()
	mission_popup.name = "MissionPopup"
	mission_popup.visible = false
	mission_popup.z_index = 100
	mission_popup.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.05, 0.05, 0.92)
	style.border_color = Color.WHITE
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	mission_popup.add_theme_stylebox_override("panel", style)

	get_parent().add_child(mission_popup)

	mission_popup.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	mission_popup.offset_left = -380
	mission_popup.offset_top = 24
	mission_popup.offset_right = -24
	mission_popup.offset_bottom = 110

	var popup_container: VBoxContainer = VBoxContainer.new()
	popup_container.name = "PopupContainer"
	popup_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	popup_container.offset_left = 14
	popup_container.offset_top = 10
	popup_container.offset_right = -14
	popup_container.offset_bottom = -10
	mission_popup.add_child(popup_container)

	var popup_title: Label = Label.new()
	popup_title.text = "Nueva misión"
	popup_title.add_theme_color_override("font_color", Color(1, 0.9, 0.2, 1))
	popup_title.add_theme_font_size_override("font_size", 18)
	popup_container.add_child(popup_title)

	mission_popup_label = Label.new()
	mission_popup_label.text = ""
	mission_popup_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mission_popup_label.add_theme_color_override("font_color", Color.WHITE)
	mission_popup_label.add_theme_font_size_override("font_size", 15)
	popup_container.add_child(mission_popup_label)

	mission_popup_timer = Timer.new()
	mission_popup_timer.one_shot = true
	mission_popup_timer.wait_time = 3.0
	mission_popup_timer.timeout.connect(_hide_mission_popup)
	add_child(mission_popup_timer)

func _ensure_missions_panel() -> void:
	if missions_panel != null:
		return

	missions_panel = Panel.new()
	missions_panel.name = "MissionsPanel"
	missions_panel.z_index = 50

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.border_color = Color.BLACK
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_top = 10
	style.content_margin_right = 10
	style.content_margin_bottom = 10
	missions_panel.add_theme_stylebox_override("panel", style)

	panel.add_child(missions_panel)

	missions_panel.position = missions_button.position + Vector2(-5, missions_button.size.y + 5)
	missions_panel.size = missions_button.size + Vector2(10, 10)
	missions_panel.custom_minimum_size = missions_button.size + Vector2(10, 10)
	missions_panel.visible = false

	missions_container = VBoxContainer.new()
	missions_container.name = "MissionsContainer"
	missions_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	missions_container.offset_left = 10
	missions_container.offset_top = 10
	missions_container.offset_right = -10
	missions_container.offset_bottom = -10
	missions_container.add_theme_constant_override("separation", 8)
	missions_panel.add_child(missions_container)

func _on_mission_started(mission: Dictionary) -> void:
	var title: String = mission.get("title", "")

	if title == "":
		return

	mission_popup_label.text = title
	mission_popup.show()
	mission_popup_timer.start()

	_refresh_missions_ui()

func _hide_mission_popup() -> void:
	if mission_popup != null:
		mission_popup.hide()

func _refresh_missions_ui() -> void:
	_refresh_mission_button_text()

	if missions_panel == null or missions_container == null:
		return

	for child in missions_container.get_children():
		child.queue_free()

	var active_missions: Array = GameManager.get_active_missions()
	var completed_missions: Array = GameManager.get_completed_missions()

	active_missions.reverse()
	completed_missions.reverse()

	if active_missions.is_empty() and completed_missions.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "Todavía no tienes misiones."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.add_theme_color_override("font_color", Color.BLACK)
		empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		missions_container.add_child(empty_label)
		return

	for mission in active_missions:
		_add_mission_label(mission, false)

	for mission in completed_missions:
		_add_mission_label(mission, true)

func _refresh_mission_button_text() -> void:
	if mission_button_label == null:
		return

	var current_mission_title: String = GameManager.get_current_mission_title()

	if current_mission_title == "":
		mission_button_label.text = "Misiones"
	else:
		mission_button_label.text = current_mission_title

func _add_mission_label(mission: Dictionary, completed: bool) -> void:
	var label: Label = Label.new()

	if completed:
		label.text = "✓ " + mission["title"]
		label.modulate = Color(1, 1, 1, 0.45)
	else:
		label.text = "• " + mission["title"]
		label.modulate = Color.WHITE

	label.add_theme_color_override("font_color", Color.BLACK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", 15)

	missions_container.add_child(label)

# -------------------------
# PANEL DE STATS
# -------------------------

func _create_stats_display() -> void:
	if stats_panel != null:
		return

	stats_button.hide()
	stats_button.disabled = true
	stats_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

	stats_panel = Panel.new()
	stats_panel.name = "StatsDisplay"
	stats_panel.z_index = 10

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.82, 0.82, 0.82, 1.0)
	style.border_color = Color(0.35, 0.35, 0.35, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(5)
	style.content_margin_left = 8
	style.content_margin_top = 8
	style.content_margin_right = 8
	style.content_margin_bottom = 8
	stats_panel.add_theme_stylebox_override("panel", style)

	panel.add_child(stats_panel)

	stats_panel.position = stats_button.position
	stats_panel.size = stats_button.size
	stats_panel.custom_minimum_size = stats_button.size

	stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	stats_container.offset_left = 8
	stats_container.offset_top = 8
	stats_container.offset_right = -8
	stats_container.offset_bottom = -8
	stats_container.add_theme_constant_override("separation", 12)
	stats_panel.add_child(stats_container)

	_refresh_stats_display()

func _refresh_stats_display() -> void:
	if stats_container == null:
		return

	for child in stats_container.get_children():
		child.queue_free()

	var vida_text: String = _format_stat_value(GameManager.vida)
	var velocidad_text: String = _format_stat_value(GameManager.velocidad_base / 100.0)
	var resistencia_text: String = _format_stat_value(GameManager.resistencia)
	var fuerza_text: String = _format_stat_value(GameManager.fuerza)

	_add_stat_row(ICON_VIDA_PATH, "❤️", "Vida", vida_text)
	_add_stat_row(ICON_VELOCIDAD_PATH, "⚡", "Velocidad", velocidad_text)
	_add_stat_row(ICON_RESISTENCIA_PATH, "🛡", "Resistencia", resistencia_text)
	_add_stat_row(ICON_FUERZA_PATH, "💪", "Fuerza", fuerza_text)

func _add_stat_row(icon_path: String, fallback_icon: String, tooltip: String, value_text: String) -> void:
	var row: HBoxContainer = HBoxContainer.new()
	row.name = tooltip + "Row"
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 6)
	stats_container.add_child(row)

	if ResourceLoader.exists(icon_path):
		var icon_texture: Texture2D = load(icon_path) as Texture2D

		var icon_texture_rect: TextureRect = TextureRect.new()
		icon_texture_rect.texture = icon_texture
		icon_texture_rect.tooltip_text = tooltip
		icon_texture_rect.custom_minimum_size = Vector2(24, 24)
		icon_texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(icon_texture_rect)
	else:
		var icon_label: Label = Label.new()
		icon_label.text = fallback_icon
		icon_label.tooltip_text = tooltip
		icon_label.custom_minimum_size = Vector2(26, 26)
		icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		icon_label.add_theme_font_size_override("font_size", 18)
		row.add_child(icon_label)

	var value_label: Label = Label.new()
	value_label.text = value_text
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_color_override("font_color", Color.BLACK)
	value_label.add_theme_font_size_override("font_size", 16)
	row.add_child(value_label)

func _format_stat_value(value: float) -> String:
	if is_equal_approx(value, roundf(value)):
		return str(int(roundf(value)))

	var formatted: String = "%.1f" % value
	return formatted.replace(".", ",")
