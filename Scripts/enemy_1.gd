extends CharacterBody2D

@export var speed: float = 80.0
@export var direction: int = -1

@export var vida_maxima: float = 10.0
@export var damage: float = 10.0
@export var damage_cooldown: float = 1.0
@export var stomp_cooldown: float = 0.15

@export var llapis_scene: PackedScene
@export_file("*.tscn") var llapis_scene_path: String = "res://Scenes/Llapis.tscn"

@export var drop_offset: Vector2 = Vector2(0, -16)

@onready var damage_area: Area2D = get_node_or_null("DamageArea") as Area2D

var vida: float = 10.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_damage: bool = true
var can_receive_stomp: bool = true
var is_dead: bool = false

func _ready() -> void:
	add_to_group("enemy")
	vida = vida_maxima
	_connect_damage_area()
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

	_check_damage_area_contacts()

func _connect_damage_area() -> void:
	if damage_area == null:
		push_warning(name + " no tiene un nodo hijo llamado DamageArea.")
		return

	damage_area.monitoring = true
	damage_area.monitorable = true

	if not damage_area.body_entered.is_connected(_on_damage_area_body_entered):
		damage_area.body_entered.connect(_on_damage_area_body_entered)

	if not damage_area.area_entered.is_connected(_on_damage_area_area_entered):
		damage_area.area_entered.connect(_on_damage_area_area_entered)

func _check_damage_area_contacts() -> void:
	if damage_area == null:
		return

	for body in damage_area.get_overlapping_bodies():
		_handle_player_contact(body)

	for area in damage_area.get_overlapping_areas():
		_handle_player_contact(area)

func _on_damage_area_body_entered(body: Node) -> void:
	_handle_player_contact(body)

func _on_damage_area_area_entered(area: Area2D) -> void:
	_handle_player_contact(area)

func _handle_player_contact(collider: Node) -> void:
	if is_dead:
		return

	var player: CharacterBody2D = _get_player_from_collider(collider)

	if player == null:
		return

	if _is_player_stomping(player):
		return

	_damage_player(player)

func _get_player_from_collider(collider: Node) -> CharacterBody2D:
	var current: Node = collider

	while current != null:
		if current is CharacterBody2D:
			if current.is_in_group("player") or current.has_method("receive_damage"):
				return current as CharacterBody2D

		current = current.get_parent()

	return null

func _is_player_stomping(player: CharacterBody2D) -> bool:
	if player.velocity.y <= 0.0:
		return false

	return player.global_position.y < global_position.y - 4.0

func _damage_player(player: CharacterBody2D) -> void:
	if not can_damage:
		return

	if not player.has_method("receive_damage"):
		return

	player.receive_damage(damage)

	can_damage = false
	await get_tree().create_timer(damage_cooldown).timeout
	can_damage = true

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

	_drop_llapis()

	queue_free()

func _drop_llapis() -> void:
	var scene: PackedScene = _get_llapis_scene()

	if scene == null:
		push_warning(name + " no puede soltar lápiz porque no encuentra la escena.")
		return

	var drop: Node = scene.instantiate()
	get_parent().add_child(drop)

	if drop is Node2D:
		var drop_node: Node2D = drop as Node2D
		drop_node.global_position = global_position + drop_offset

func _get_llapis_scene() -> PackedScene:
	if llapis_scene != null:
		return llapis_scene

	if llapis_scene_path != "" and ResourceLoader.exists(llapis_scene_path):
		return load(llapis_scene_path) as PackedScene

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
