extends Label

func _ready() -> void:
	add_theme_color_override("font_color", Color(0, 0, 0, 1))
	add_theme_color_override("font_shadow_color", Color(1, 1, 1, 1))
	add_theme_constant_override("shadow_offset_x", 1)
	add_theme_constant_override("shadow_offset_y", 1)
	add_theme_font_size_override("font_size", 18)

	text = "SkillCoins: %d" % GameManager.skillcoins

	if not GameManager.skillcoins_changed.is_connected(_on_skillcoins_changed):
		GameManager.skillcoins_changed.connect(_on_skillcoins_changed)

func _on_skillcoins_changed(total: int) -> void:
	text = "SkillCoins: %d" % total
