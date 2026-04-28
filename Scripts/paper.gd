extends Area2D

@export var pickup_delay: float = 0.6

var can_pickup: bool = false
var already_picked: bool = false

func _ready() -> void:
	monitoring = true

	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)

	can_pickup = false

	await get_tree().create_timer(pickup_delay).timeout

	can_pickup = true
	_check_overlapping_bodies()

func _on_body_entered(body: Node) -> void:
	if already_picked:
		return

	if not can_pickup:
		return

	_try_pickup(body)

func _check_overlapping_bodies() -> void:
	if already_picked:
		return

	for body in get_overlapping_bodies():
		_try_pickup(body)

func _try_pickup(body: Node) -> void:
	if already_picked:
		return

	if not _is_player(body):
		return

	already_picked = true
	GameManager.obtain_paper()
	queue_free()

func _is_player(body: Node) -> bool:
	if body.is_in_group("player"):
		return true

	if body.has_method("add_coin"):
		return true

	if str(body.name).to_lower().contains("player"):
		return true

	return false
