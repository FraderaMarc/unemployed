extends Node

signal skillcoins_changed(total)
signal skill_tree_unlocked

signal mission_started(mission)
signal mission_completed(mission)
signal missions_changed

signal player_stats_changed
signal player_died

const MISSIONS: Dictionary = {
	"investiga_hormiguero": {
		"title": "Investiga cómo salir del hormiguero",
		"description": "Busca pistas para descubrir cómo escapar del hormiguero.",
		"next": ""
	},

	"completa_curriculum": {
		"title": "Completa el currículum",
		"description": "Abre el currículum y desbloquea tu primera habilidad.",
		"next": ""
	}
}

var skillcoins: int = 1
var llapis: bool = false
var paper: bool = false
var intro_dialogue_played: bool = false
var skill_tree_opened_once: bool = false
var first_skill_unlocked: bool = false

var skill_levels: Dictionary = {}

var missions: Array = []

# -------------------------
# RESPAWN / CHECKPOINTS
# -------------------------

var respawn_position: Vector2 = Vector2.ZERO
var has_respawn_position: bool = false

# -------------------------
# ENEMIGOS DERROTADOS
# -------------------------
# Se mantiene para compatibilidad con scripts antiguos.
# Para enemigos que sueltan llapis/paper, es mejor depender de GameManager.llapis / GameManager.paper.
var defeated_enemies: Dictionary = {}

# -------------------------
# ATRIBUTOS DEL PERSONAJE
# -------------------------

var vida_maxima: float = 50.0
var vida: float = 50.0

var velocidad_base: float = 225.0
var velocidad_sprint: float = 320.0

# Resistencia máxima funciona como "escudo":
# daño final = daño recibido - resistencia_maxima
var resistencia_maxima: float = 0.0

# Resistencia actual se sigue usando para el sprint/stamina.
var resistencia: float = 0.0
var resistencia_gasto_por_segundo: float = 25.0
var resistencia_recuperacion_por_segundo: float = 18.0

var fuerza: float = 5.0


# -------------------------
# RESPAWN / CHECKPOINTS
# -------------------------

func set_initial_respawn_position(position: Vector2) -> void:
	if has_respawn_position:
		return

	respawn_position = position
	has_respawn_position = true


func set_respawn_position(position: Vector2) -> void:
	respawn_position = position
	has_respawn_position = true


func get_respawn_position(default_position: Vector2 = Vector2.ZERO) -> Vector2:
	if has_respawn_position:
		return respawn_position

	return default_position


func clear_respawn_position() -> void:
	respawn_position = Vector2.ZERO
	has_respawn_position = false


# -------------------------
# ENEMIGOS DERROTADOS
# -------------------------

func is_enemy_defeated(enemy_ref: Variant = "") -> bool:
	var enemy_id: String = _get_enemy_key(enemy_ref)

	if enemy_id == "":
		return false

	return bool(defeated_enemies.get(enemy_id, false))


func mark_enemy_defeated(enemy_ref: Variant = "") -> void:
	var enemy_id: String = _get_enemy_key(enemy_ref)

	if enemy_id == "":
		return

	defeated_enemies[enemy_id] = true


# Alias antiguo. No borrar.
func register_defeated_enemy(enemy_ref: Variant = "") -> void:
	mark_enemy_defeated(enemy_ref)


func unregister_defeated_enemy(enemy_ref: Variant = "") -> void:
	var enemy_id: String = _get_enemy_key(enemy_ref)

	if enemy_id == "":
		return

	defeated_enemies.erase(enemy_id)


func clear_defeated_enemies() -> void:
	defeated_enemies.clear()


func _get_enemy_key(enemy_ref: Variant) -> String:
	if enemy_ref == null:
		return ""

	if enemy_ref is String:
		return String(enemy_ref).strip_edges()

	if enemy_ref is Node:
		var node: Node = enemy_ref as Node
		var scene_path: String = ""

		if get_tree() != null and get_tree().current_scene != null:
			scene_path = get_tree().current_scene.scene_file_path

		return scene_path + "::" + str(node.get_path())

	return str(enemy_ref).strip_edges()


# -------------------------
# SKILLCOINS / OBJETOS
# -------------------------

func add_skillcoin(amount: int = 1) -> void:
	skillcoins += amount
	skillcoins_changed.emit(skillcoins)


func spend_skillcoin(amount: int = 1) -> bool:
	if skillcoins < amount:
		return false

	skillcoins -= amount
	skillcoins_changed.emit(skillcoins)
	return true


func obtain_llapis() -> void:
	llapis = true
	_check_skill_tree_unlock()


func obtain_paper() -> void:
	paper = true
	_check_skill_tree_unlock()


func has_both_items() -> bool:
	return llapis and paper


func _check_skill_tree_unlock() -> void:
	if has_both_items() and not skill_tree_opened_once:
		skill_tree_opened_once = true
		skill_tree_unlocked.emit()


func unlock_first_skill() -> void:
	first_skill_unlocked = true


# Usado por Mercedes.dialogue.
# No borrar: evita que el diálogo inicial se repita.
func mark_intro_dialogue_played() -> void:
	intro_dialogue_played = true


func should_play_intro_dialogue() -> bool:
	return not intro_dialogue_played


# -------------------------
# ATRIBUTOS / COMBATE
# -------------------------

func get_player_speed(is_sprinting: bool = false) -> float:
	if is_sprinting and resistencia > 0.0:
		return velocidad_sprint

	return velocidad_base


func update_stamina(delta: float, is_sprinting: bool) -> void:
	var previous_resistencia: float = resistencia

	if is_sprinting:
		resistencia -= resistencia_gasto_por_segundo * delta
	else:
		resistencia += resistencia_recuperacion_por_segundo * delta

	resistencia = clampf(resistencia, 0.0, resistencia_maxima)

	if resistencia != previous_resistencia:
		player_stats_changed.emit()


func take_damage(amount: float) -> void:
	if amount <= 0.0:
		return

	var final_damage: float = amount - resistencia_maxima
	final_damage = maxf(final_damage, 0.0)

	if final_damage <= 0.0:
		return

	vida -= final_damage
	vida = clampf(vida, 0.0, vida_maxima)

	player_stats_changed.emit()

	if vida <= 0.0:
		player_died.emit()


func heal_player(amount: float) -> void:
	if amount <= 0.0:
		return

	vida += amount
	vida = clampf(vida, 0.0, vida_maxima)

	player_stats_changed.emit()


func restore_stamina(amount: float) -> void:
	if amount <= 0.0:
		return

	resistencia += amount
	resistencia = clampf(resistencia, 0.0, resistencia_maxima)

	player_stats_changed.emit()


func get_attack_damage() -> float:
	return fuerza


func increase_attack_damage(amount: float) -> void:
	if amount <= 0.0:
		return

	fuerza += amount
	player_stats_changed.emit()


func increase_max_health(amount: float) -> void:
	if amount <= 0.0:
		return

	vida_maxima += amount
	vida += amount
	vida = clampf(vida, 0.0, vida_maxima)

	player_stats_changed.emit()


func increase_max_resistance(amount: float) -> void:
	if amount <= 0.0:
		return

	resistencia_maxima += amount
	resistencia = resistencia_maxima

	player_stats_changed.emit()


func reset_player_stats() -> void:
	vida = vida_maxima
	resistencia = resistencia_maxima
	player_stats_changed.emit()


# -------------------------
# MISIONES
# -------------------------

func start_mission(mission_id: String) -> bool:
	if has_mission(mission_id):
		return false

	if not MISSIONS.has(mission_id):
		push_warning("La misión no existe: " + mission_id)
		return false

	var mission_data: Dictionary = MISSIONS[mission_id]

	var mission: Dictionary = {
		"id": mission_id,
		"title": mission_data["title"],
		"description": mission_data["description"],
		"completed": false
	}

	missions.append(mission)
	mission_started.emit(mission)
	missions_changed.emit()

	return true


func complete_mission(mission_id: String) -> bool:
	for mission in missions:
		if mission["id"] == mission_id:
			if mission["completed"]:
				return false

			mission["completed"] = true
			mission_completed.emit(mission)
			missions_changed.emit()

			var mission_data: Dictionary = MISSIONS.get(mission_id, {})
			var next_mission: String = mission_data.get("next", "")

			if next_mission != "":
				start_mission(next_mission)

			return true

	return false


func has_mission(mission_id: String) -> bool:
	for mission in missions:
		if mission["id"] == mission_id:
			return true

	return false


func is_mission_completed(mission_id: String) -> bool:
	for mission in missions:
		if mission["id"] == mission_id:
			return mission["completed"]

	return false


func get_active_missions() -> Array:
	var active_missions: Array = []

	for mission in missions:
		if not mission["completed"]:
			active_missions.append(mission)

	return active_missions


func get_completed_missions() -> Array:
	var completed_missions: Array = []

	for mission in missions:
		if mission["completed"]:
			completed_missions.append(mission)

	return completed_missions


func get_all_missions_ordered() -> Array:
	var ordered_missions: Array = []

	for mission in missions:
		if not mission["completed"]:
			ordered_missions.push_front(mission)

	for mission in missions:
		if mission["completed"]:
			ordered_missions.push_front(mission)

	return ordered_missions


func get_current_mission_title() -> String:
	var active_missions: Array = get_active_missions()

	if active_missions.is_empty():
		return ""

	return active_missions[active_missions.size() - 1]["title"]


# -------------------------
# GUARDADO / CARGA
# -------------------------

func get_save_data() -> Dictionary:
	return {
		"skillcoins": skillcoins,
		"llapis": llapis,
		"paper": paper,
		"intro_dialogue_played": intro_dialogue_played,
		"skill_tree_opened_once": skill_tree_opened_once,
		"first_skill_unlocked": first_skill_unlocked,
		"skill_levels": skill_levels.duplicate(true),

		"respawn_position": [respawn_position.x, respawn_position.y],
		"has_respawn_position": has_respawn_position,

		"defeated_enemies": defeated_enemies.duplicate(true),

		"vida_maxima": vida_maxima,
		"vida": vida,
		"velocidad_base": velocidad_base,
		"velocidad_sprint": velocidad_sprint,
		"resistencia_maxima": resistencia_maxima,
		"resistencia": resistencia,
		"resistencia_gasto_por_segundo": resistencia_gasto_por_segundo,
		"resistencia_recuperacion_por_segundo": resistencia_recuperacion_por_segundo,
		"fuerza": fuerza,

		"missions": missions.duplicate(true)
	}


func load_save_data(data: Dictionary) -> void:
	skillcoins = int(data.get("skillcoins", 1))
	llapis = bool(data.get("llapis", false))
	paper = bool(data.get("paper", false))

	# Por defecto true para que saves antiguos no repitan el diálogo inicial.
	intro_dialogue_played = bool(data.get("intro_dialogue_played", true))

	skill_tree_opened_once = bool(data.get("skill_tree_opened_once", false))
	first_skill_unlocked = bool(data.get("first_skill_unlocked", false))
	skill_levels = data.get("skill_levels", {}).duplicate(true)

	var respawn_array: Array = data.get("respawn_position", [])
	has_respawn_position = bool(data.get("has_respawn_position", false))

	if respawn_array.size() >= 2:
		respawn_position = Vector2(float(respawn_array[0]), float(respawn_array[1]))

	defeated_enemies = data.get("defeated_enemies", {}).duplicate(true)

	vida_maxima = float(data.get("vida_maxima", 50.0))
	vida = float(data.get("vida", vida_maxima))

	velocidad_base = float(data.get("velocidad_base", 225.0))
	velocidad_sprint = float(data.get("velocidad_sprint", 320.0))

	resistencia_maxima = float(data.get("resistencia_maxima", 0.0))
	resistencia = float(data.get("resistencia", resistencia_maxima))
	resistencia_gasto_por_segundo = float(data.get("resistencia_gasto_por_segundo", 25.0))
	resistencia_recuperacion_por_segundo = float(data.get("resistencia_recuperacion_por_segundo", 18.0))

	fuerza = float(data.get("fuerza", 5.0))

	missions = data.get("missions", []).duplicate(true)

	skillcoins_changed.emit(skillcoins)
	player_stats_changed.emit()
	missions_changed.emit()


func reset_game_state() -> void:
	skillcoins = 31
	llapis = false
	paper = false
	intro_dialogue_played = false
	skill_tree_opened_once = false
	first_skill_unlocked = false
	skill_levels = {}

	missions.clear()

	clear_respawn_position()
	clear_defeated_enemies()

	vida_maxima = 50.0
	vida = 50.0

	velocidad_base = 225.0
	velocidad_sprint = 320.0

	resistencia_maxima = 0.0
	resistencia = 0.0
	resistencia_gasto_por_segundo = 25.0
	resistencia_recuperacion_por_segundo = 18.0

	fuerza = 5.0

	skillcoins_changed.emit(skillcoins)
	player_stats_changed.emit()
	missions_changed.emit()
