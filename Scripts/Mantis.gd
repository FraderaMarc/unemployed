extends CharacterBody2D

@export var persistent_enemy_id: String = ""

@export var speed: float = 80.0
@export var direction: int = -1

@export var vida_maxima: float = 80.0
@export var damage: float = 35.0
@export var damage_cooldown: float = 0.5
@export var stomp_cooldown: float = 0.15

@export var drop_scene: PackedScene
@export_file("*.tscn") var drop_scene_path: String = "res://Scenes/SkillCoin.tscn"
@export var drop_offset: Vector2 = Vector2(0, -16)

var vida: float = 10.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

var can_damage: bool = true
var can_receive_stomp: bool = true
var is_dead: bool = false

func _ready() -> void:
	var enemy_id: String = _get_persistent_enemy_id()

	if GameManager.has_method("is_enemy_defeated") and GameManager.is_enemy_defeated(enemy_id):
		queue_free()
		return

	add_to_group("enemy")
	vida = vida_maxima
	_update_sprite_direction()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	velocity.x = direction * speed

	move_and_slide()

	if is_on_wall():
		_turn_around()

func _get_persistent_enemy_id() -> String:
	if persistent_enemy_id.strip_edges() != "":
		return persistent_enemy_id

	return "%s|%s" % [scene_file_path, str(get_path())]

func get_enemy_damage() -> float:
	return damage

func receive_stomp_damage(amount: float) -> void:
	if is_dead:
		return

	if not can_receive_stomp:
		return

	can_receive_stomp = false
	receive_damage(amount)

	if is_dead:
		return

	await get_tree().create_timer(stomp_cooldown).timeout
	can_receive_stomp = true

func receive_damage(amount: float) -> void:
	if is_dead:
		return

	if amount <= 0.0:
		return

	vida -= amount

	if vida <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	_drop_item()

	if GameManager.has_method("register_defeated_enemy"):
		GameManager.register_defeated_enemy(_get_persistent_enemy_id())

	queue_free()

func _drop_item() -> void:
	var scene: PackedScene = _get_drop_scene()

	if scene == null:
		push_warning(name + " no puede soltar item porque no encuentra la escena.")
		return

	var drop: Node = scene.instantiate()
	get_parent().add_child(drop)

	if drop is Node2D:
		var drop_node: Node2D = drop as Node2D
		drop_node.global_position = global_position + drop_offset

func _get_drop_scene() -> PackedScene:
	if drop_scene != null:
		return drop_scene

	if drop_scene_path != "" and ResourceLoader.exists(drop_scene_path):
		return load(drop_scene_path) as PackedScene

	return null

func _turn_around() -> void:
	direction *= -1
	_update_sprite_direction()

func _update_sprite_direction() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D") as Sprite2D

	if sprite != null:
		sprite.flip_h = direction > 0

	var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D

	if animated_sprite != null:
		animated_sprite.flip_h = direction > 0
