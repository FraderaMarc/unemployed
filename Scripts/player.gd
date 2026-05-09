extends CharacterBody2D

const JUMP_VELOCITY: float = -325.0
const ENEMY_BOUNCE_VELOCITY: float = -240.0
const ENEMY_DAMAGE_COOLDOWN: float = 1.0
const CURRICULUM_SCENE: PackedScene = preload("res://Scenes/curriculum.tscn")

@onready var anim: AnimatedSprite2D = $Sprite2D
@onready var hud: Node = get_node_or_null("/root/Map/CanvasLayer")

var coins: int = 0
var can_move: bool = true
var can_receive_enemy_damage: bool = true
var is_restarting: bool = false
var curriculum: Control = null


func _ready() -> void:
	add_to_group("player")

	# Si todavía no hay checkpoint, esta posición será el respawn inicial.
	# Si ya hay checkpoint, NO lo sobrescribe.
	GameManager.set_initial_respawn_position(global_position)

	# Al cargar/reiniciar la escena, coloca al jugador en:
	# - último checkpoint si existe
	# - posición inicial si no existe checkpoint
	global_position = GameManager.get_respawn_position(global_position)

	if hud != null:
		curriculum = CURRICULUM_SCENE.instantiate()
		hud.add_child(curriculum)
		curriculum.hide()
	else:
		push_warning("No se ha encontrado /root/Map/CanvasLayer. No se puede añadir el curriculum al HUD.")

	if not GameManager.skill_tree_unlocked.is_connected(_on_skill_tree_unlocked):
		GameManager.skill_tree_unlocked.connect(_on_skill_tree_unlocked)

	if not GameManager.player_died.is_connected(_on_player_died):
		GameManager.player_died.connect(_on_player_died)

	if GameManager.has_both_items() and GameManager.skill_tree_opened_once:
		_on_skill_tree_unlocked()


func add_coin(amount: int = 1) -> void:
	coins += amount

	if hud != null and hud.has_method("set_coins"):
		hud.set_coins(coins)


func _on_skill_tree_unlocked() -> void:
	if curriculum != null and curriculum.has_method("open_skill_tree_from_items"):
		curriculum.open_skill_tree_from_items()


func _physics_process(delta: float) -> void:
	if is_restarting:
		return

	if Input.is_action_just_pressed("open_curriculum"):
		if not GameManager.first_skill_unlocked:
			return

		if not _is_skill_tree_open():
			if curriculum != null:
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

	var was_falling: bool = velocity.y > 0.0

	move_and_slide()

	_check_enemy_collisions(was_falling)

	if not is_on_floor() and velocity.y < 0.0:
		anim.play("Jump")
	elif direction != 0.0:
		anim.play("Walk")
	else:
		anim.play("Idle")


func _check_enemy_collisions(was_falling: bool) -> void:
	for i in get_slide_collision_count():
		var collision: KinematicCollision2D = get_slide_collision(i)

		if collision == null:
			continue

		var collider: Object = collision.get_collider()

		if not collider is Node:
			continue

		var enemy: Node = collider as Node

		if not _is_enemy(enemy):
			continue

		var normal: Vector2 = collision.get_normal()

		if was_falling and normal.y < -0.5:
			_damage_enemy_from_stomp(enemy)
			bounce_from_enemy()
			return

		_receive_lateral_enemy_damage(enemy)


func _is_enemy(node: Node) -> bool:
	if node.is_in_group("enemy"):
		return true

	if node.has_method("receive_stomp_damage"):
		return true

	if node.has_method("get_enemy_damage"):
		return true

	return false


func _damage_enemy_from_stomp(enemy: Node) -> void:
	var damage: float = attack_damage()

	if enemy.has_method("receive_stomp_damage"):
		enemy.receive_stomp_damage(damage)
		return

	if enemy.has_method("receive_damage"):
		enemy.receive_damage(damage)


func _receive_lateral_enemy_damage(enemy: Node) -> void:
	if not can_receive_enemy_damage:
		return

	var damage: float = 10.0

	if enemy.has_method("get_enemy_damage"):
		damage = enemy.get_enemy_damage()

	receive_damage(damage)

	can_receive_enemy_damage = false
	await get_tree().create_timer(ENEMY_DAMAGE_COOLDOWN).timeout
	can_receive_enemy_damage = true


func receive_damage(amount: float) -> void:
	if is_restarting:
		return

	GameManager.take_damage(amount)


func attack_damage() -> float:
	return GameManager.get_attack_damage()


func bounce_from_enemy() -> void:
	velocity.y = ENEMY_BOUNCE_VELOCITY


func _on_player_died() -> void:
	if is_restarting:
		return

	is_restarting = true
	can_move = false
	velocity = Vector2.ZERO
	anim.play("Idle")

	await _show_death_screen_and_restart()


func _show_death_screen_and_restart() -> void:
	var black_screen: ColorRect = ColorRect.new()
	black_screen.name = "DeathBlackScreen"
	black_screen.color = Color(0, 0, 0, 0)
	black_screen.mouse_filter = Control.MOUSE_FILTER_STOP
	black_screen.z_index = 9999

	if hud != null:
		hud.add_child(black_screen)
	else:
		add_child(black_screen)

	black_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_screen.offset_left = 0
	black_screen.offset_top = 0
	black_screen.offset_right = 0
	black_screen.offset_bottom = 0

	var tween: Tween = create_tween()
	tween.tween_property(black_screen, "color", Color(0, 0, 0, 1), 0.6)

	await tween.finished
	await get_tree().create_timer(0.6).timeout

	GameManager.reset_player_stats()
	get_tree().reload_current_scene()


func _is_any_menu_open() -> bool:
	if curriculum != null and curriculum.visible:
		return true

	var skill_tree: Node = null

	if hud != null:
		skill_tree = hud.get_node_or_null("skill_tree")

	return skill_tree != null and skill_tree.visible


func _is_skill_tree_open() -> bool:
	var skill_tree: Node = null

	if hud != null:
		skill_tree = hud.get_node_or_null("skill_tree")

	return skill_tree != null and skill_tree.visible


func get_save_data() -> Dictionary:
	return {
		"coins": coins
	}


func load_save_data(data: Dictionary) -> void:
	coins = int(data.get("coins", coins))

	if hud != null and hud.has_method("set_coins"):
		hud.set_coins(coins)
