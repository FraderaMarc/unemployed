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
	}
}

var skillcoins: int = 1
var llapis: bool = false
var paper: bool = false
var skill_tree_opened_once: bool = false
var first_skill_unlocked: bool = false

var missions: Array = []

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
