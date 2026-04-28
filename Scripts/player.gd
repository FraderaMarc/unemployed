extends CharacterBody2D

const JUMP_VELOCITY: float = -325.0
const CURRICULUM_SCENE: PackedScene = preload("res://Scenes/curriculum.tscn")

@onready var anim: AnimatedSprite2D = $Sprite2D
@onready var hud: CanvasLayer = get_node("/root/Map/CanvasLayer")

var coins: int = 0
var can_move: bool = true
var curriculum: Control = null

func _ready() -> void:
	curriculum = CURRICULUM_SCENE.instantiate()
	hud.add_child(curriculum)
	curriculum.hide()

	if not GameManager.skill_tree_unlocked.is_connected(_on_skill_tree_unlocked):
		GameManager.skill_tree_unlocked.connect(_on_skill_tree_unlocked)

	if not GameManager.player_died.is_connected(_on_player_died):
		GameManager.player_died.connect(_on_player_died)

	if GameManager.has_both_items() and GameManager.skill_tree_opened_once:
		_on_skill_tree_unlocked()

func add_coin(amount: int = 1) -> void:
	coins += amount
	hud.set_coins(coins)

func _on_skill_tree_unlocked() -> void:
	if curriculum != null:
		curriculum.open_skill_tree_from_items()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("open_curriculum"):
		if not GameManager.first_skill_unlocked:
			return

		if not _is_skill_tree_open():
			if curriculum.visible:
				curriculum.hide()
			else:
				curriculum.show()

	if not can_move or _is_any_menu_open():
		velocity = Vector2.ZERO
		anim.play("Idle")
		move_and_slide()
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var direction: float = Input.get_axis("ui_left", "ui_right")

	var wants_to_sprint: bool = false

	if InputMap.has_action("sprint"):
		wants_to_sprint = Input.is_action_pressed("sprint")

	var is_sprinting: bool = wants_to_sprint and direction != 0.0 and GameManager.resistencia > 0.0

	GameManager.update_stamina(delta, is_sprinting)

	var current_speed: float = GameManager.get_player_speed(is_sprinting)

	if direction != 0.0:
		velocity.x = direction * current_speed
		anim.flip_h = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, GameManager.velocidad_base)

	move_and_slide()

	if not is_on_floor() and velocity.y < 0.0:
		anim.play("Jump")
	elif direction != 0.0:
		anim.play("Walk")
	else:
		anim.play("Idle")

func receive_damage(amount: float) -> void:
	GameManager.take_damage(amount)

func attack_damage() -> float:
	return GameManager.get_attack_damage()

func _on_player_died() -> void:
	can_move = false
	velocity = Vector2.ZERO
	anim.play("Idle")
	print("El jugador ha muerto")

func _is_any_menu_open() -> bool:
	if curriculum != null and curriculum.visible:
		return true

	var skill_tree: Node = hud.get_node_or_null("skill_tree")
	return skill_tree != null and skill_tree.visible

func _is_skill_tree_open() -> bool:
	var skill_tree: Node = hud.get_node_or_null("skill_tree")
	return skill_tree != null and skill_tree.visible
