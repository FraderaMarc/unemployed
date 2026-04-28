extends CanvasLayer

@onready var coin_label: Label = $Control/Label

var health_panel: Panel = null
var health_bar: ProgressBar = null
var health_label: Label = null

func _ready() -> void:
	_create_health_bar()

	if not GameManager.player_stats_changed.is_connected(_refresh_health_bar):
		GameManager.player_stats_changed.connect(_refresh_health_bar)

	_refresh_health_bar()

func set_coins(amount: int) -> void:
	coin_label.text = str(amount)

func _create_health_bar() -> void:
	if health_panel != null:
		return

	health_panel = Panel.new()
	health_panel.name = "HealthPanel"

	var panel_style: StyleBoxFlat = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.08, 0.85)
	panel_style.border_color = Color.BLACK
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(5)
	health_panel.add_theme_stylebox_override("panel", panel_style)

	add_child(health_panel)

	health_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	health_panel.offset_left = -260
	health_panel.offset_top = 20
	health_panel.offset_right = -20
	health_panel.offset_bottom = 56

	health_bar = ProgressBar.new()
	health_bar.name = "HealthBar"
	health_bar.min_value = 0
	health_bar.max_value = GameManager.vida_maxima
	health_bar.value = GameManager.vida
	health_bar.show_percentage = false

	var background_style: StyleBoxFlat = StyleBoxFlat.new()
	background_style.bg_color = Color(0.25, 0.25, 0.25, 1)
	background_style.set_corner_radius_all(4)

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.05, 0.05, 1)
	fill_style.set_corner_radius_all(4)

	health_bar.add_theme_stylebox_override("background", background_style)
	health_bar.add_theme_stylebox_override("fill", fill_style)

	health_panel.add_child(health_bar)

	health_bar.position = Vector2(8, 8)
	health_bar.size = Vector2(224, 20)

	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.add_theme_color_override("font_color", Color.WHITE)
	health_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	health_label.add_theme_constant_override("shadow_offset_x", 1)
	health_label.add_theme_constant_override("shadow_offset_y", 1)
	health_label.add_theme_font_size_override("font_size", 14)

	health_panel.add_child(health_label)

	health_label.position = Vector2(8, 6)
	health_label.size = Vector2(224, 24)

func _refresh_health_bar() -> void:
	if health_bar == null or health_label == null:
		return

	health_bar.max_value = GameManager.vida_maxima
	health_bar.value = GameManager.vida

	health_label.text = "%d / %d" % [
		int(GameManager.vida),
		int(GameManager.vida_maxima)
	]
