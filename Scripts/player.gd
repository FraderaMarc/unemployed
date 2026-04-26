extends CharacterBody2D

const SPEED = 225
const JUMP_VELOCITY = -325
const CURRICULUM_SCENE = preload("res://Scenes/curriculum.tscn")

@onready var anim = $Sprite2D
@onready var hud = get_node("/root/Map/CanvasLayer")

var coins: int = 0
var can_move = true
var curriculum = null

func _ready() -> void:
	curriculum = CURRICULUM_SCENE.instantiate()
	hud.add_child(curriculum)
	curriculum.hide()

	GameManager.skill_tree_unlocked.connect(_on_skill_tree_unlocked)

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

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction != 0:
		velocity.x = direction * SPEED
		anim.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

	if not is_on_floor() and velocity.y < 0:
		anim.play("Jump")
	elif direction != 0:
		anim.play("Walk")
	else:
		anim.play("Idle")

func _is_any_menu_open() -> bool:
	if curriculum != null and curriculum.visible:
		return true

	var skill_tree = hud.get_node_or_null("skill_tree")
	return skill_tree != null and skill_tree.visible

func _is_skill_tree_open() -> bool:
	var skill_tree = hud.get_node_or_null("skill_tree")
	return skill_tree != null and skill_tree.visible
