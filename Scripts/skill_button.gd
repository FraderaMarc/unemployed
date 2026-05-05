extends TextureButton
class_name SkillNode

@onready var panel: Panel = $Panel
@onready var label: Label = $MarginContainer/Label
@onready var line_2d: Line2D = $Line2D

func _ready() -> void:
	if get_parent() is SkillNode:
		line_2d.add_point(global_position + size / 2)
		line_2d.add_point(get_parent().global_position + size / 2)

func set_level_text(current_level: int, max_level: int) -> void:
	if label == null:
		return

	label.text = "%d/%d" % [current_level, max_level]

func set_unlocked_visual(is_unlocked: bool) -> void:
	if panel != null:
		panel.show_behind_parent = is_unlocked

	if line_2d != null:
		if is_unlocked:
			line_2d.default_color = Color(0.945, 0.929, 0.0, 1.0)
		else:
			line_2d.default_color = Color(0.27387273, 0.27387273, 0.27387273, 1.0)

func _on_pressed() -> void:
	# La lógica real de subir habilidades la controla skill_tree.gd.
	# Esta función se deja para no romper la señal conectada en la escena.
	pass
