extends Label

func _ready() -> void:
	text = "SkillCoins: %d" % GameManager.skillcoins
	GameManager.skillcoins_changed.connect(_on_skillcoins_changed)

func _on_skillcoins_changed(total: int) -> void:
	text = "SkillCoins: %d" % total
