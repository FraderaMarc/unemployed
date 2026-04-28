extends CharacterBody2D

@export var speed: float = 80.0
@export var damage: float = 25.0
@export var direction: int = -1
@export var drop_scene: PackedScene
@export var drop_offset: Vector2 = Vector2(0, -16)

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_damage: bool = true
var is_dead: bool = false

func _ready() -> void:
	_update_sprite_direction()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	velocity.x = direction * speed

	move_and_slide()

	if is_on_wall():
		_turn_around()

func _turn_around() -> void:
	direction *= -1
	_update_sprite_direction()

func _update_sprite_direction() -> void:
	var sprite: Sprite2D = get_node_or_null("Sprite2D")
	if sprite != null:
		sprite.flip_h = direction > 0

	var animated_sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")
	if animated_sprite != null:
		animated_sprite.flip_h = direction > 0

func _on_damage_area_body_entered(body: Node) -> void:
	if is_dead:
		return

	if not can_damage:
		return

	if body.has_method("receive_damage"):
		body.receive_damage(damage)

		can_damage = false
		await get_tree().create_timer(1.0).timeout
		can_damage = true

func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	_drop_item()

	queue_free()

func _drop_item() -> void:
	if drop_scene == null:
		return

	var drop: Node = drop_scene.instantiate()
	get_parent().add_child(drop)

	if drop is Node2D:
		drop.global_position = global_position + drop_offset
