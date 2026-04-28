extends CharacterBody2D

@export var speed: float = 80.0
@export var direction: int = -1
@export var damage: float = 25.0
@export var damage_cooldown: float = 1.0

@export var paper_scene: PackedScene
@export var drop_offset: Vector2 = Vector2(0, -16)

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var can_damage: bool = true
var is_dead: bool = false

func _ready() -> void:
	_connect_damage_area()
	_update_sprite_direction()

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# El enemigo cae por gravedad, pero nunca salta.
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0.0

	# Movimiento horizontal.
	velocity.x = direction * speed

	move_and_slide()

	# Si choca con una pared, gira.
	if is_on_wall():
		_turn_around()

func _connect_damage_area() -> void:
	var damage_area: Area2D = get_node_or_null("DamageArea") as Area2D

	if damage_area == null:
		push_warning(name + " no tiene un nodo hijo llamado DamageArea.")
		return

	if not damage_area.body_entered.is_connected(_on_damage_area_body_entered):
		damage_area.body_entered.connect(_on_damage_area_body_entered)

func _on_damage_area_body_entered(body: Node) -> void:
	if is_dead:
		return

	if not can_damage:
		return

	if body.has_method("receive_damage"):
		body.receive_damage(damage)

		can_damage = false
		await get_tree().create_timer(damage_cooldown).timeout
		can_damage = true

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

func die() -> void:
	if is_dead:
		return

	is_dead = true
	velocity = Vector2.ZERO

	_drop_paper()

	queue_free()

func _drop_paper() -> void:
	if paper_scene == null:
		push_warning(name + " no tiene asignada la escena del papel.")
		return

	var drop: Node = paper_scene.instantiate()
	get_parent().add_child(drop)

	if drop is Node2D:
		var drop_node: Node2D = drop as Node2D
		drop_node.global_position = global_position + drop_offset
