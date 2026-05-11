extends Node

const SAVE_FILE_NAME: String = "savegame.json"
const SAVE_PATH: String = "user://" + SAVE_FILE_NAME

# Cambia esta ruta si tu primera escena jugable no es Map.tscn.
const FIRST_GAME_SCENE: String = "res://Scenes/Map.tscn"

const INTRO_DIALOGUE_PATH: String = "res://assets/Dialogues/Mercedes.dialogue"
const INTRO_DIALOGUE_TITLE: String = "start"

var pending_player_position: Vector2 = Vector2.ZERO
var has_pending_player_position: bool = false
var pending_player_data: Dictionary = {}

var start_intro_dialogue: bool = false
var is_loading_game: bool = false
var is_autosaving: bool = false


func _ready() -> void:
	call_deferred("_connect_game_manager_signals")


func _connect_game_manager_signals() -> void:
	if not GameManager.missions_changed.is_connected(_on_game_progress_changed):
		GameManager.missions_changed.connect(_on_game_progress_changed)


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func new_game() -> void:
	is_loading_game = false
	delete_save()
	GameManager.reset_game_state()

	start_intro_dialogue = true

	var error: Error = get_tree().change_scene_to_file(FIRST_GAME_SCENE)

	if error != OK:
		push_error("No se ha podido cargar la escena inicial: " + FIRST_GAME_SCENE)


func continue_game() -> bool:
	start_intro_dialogue = false
	is_loading_game = true

	var save_data: Dictionary = _read_save_file()

	if save_data.is_empty():
		is_loading_game = false
		return false

	var game_manager_data: Dictionary = save_data.get("game_manager", {})
	GameManager.load_save_data(game_manager_data)

	var position_array: Array = save_data.get("player_position", [])
	has_pending_player_position = position_array.size() >= 2

	if has_pending_player_position:
		pending_player_position = Vector2(
			float(position_array[0]),
			float(position_array[1])
		)

	pending_player_data = save_data.get("player", {})

	var scene_path: String = str(save_data.get("scene_path", FIRST_GAME_SCENE))
	var error: Error = get_tree().change_scene_to_file(scene_path)

	if error != OK:
		is_loading_game = false
		push_error("No se ha podido cargar la escena guardada: " + scene_path)
		return false

	call_deferred("_apply_pending_player_after_scene_loaded")
	return true


func save_checkpoint(spawn_position: Vector2) -> bool:
	GameManager.set_respawn_position(spawn_position)
	return _save_game_at_position(spawn_position)


func save_current_game() -> bool:
	var player: Node = get_player()

	if player == null:
		push_warning("No se puede guardar porque no hay ningún nodo en el grupo 'player'.")
		return false

	if not player is Node2D:
		push_warning("El jugador encontrado no es Node2D.")
		return false

	return _save_game_at_position((player as Node2D).global_position)


func save_progress_at_respawn_position() -> bool:
	var spawn_position: Vector2 = _get_respawn_or_player_position()
	return _save_game_at_position(spawn_position)


func _on_game_progress_changed() -> void:
	if is_loading_game:
		return

	if is_autosaving:
		return

	call_deferred("_autosave_progress_at_respawn_position")


func _autosave_progress_at_respawn_position() -> void:
	if is_loading_game:
		return

	if is_autosaving:
		return

	is_autosaving = true
	save_progress_at_respawn_position()
	is_autosaving = false


func _get_respawn_or_player_position() -> Vector2:
	var fallback_position: Vector2 = Vector2.ZERO
	var player: Node = get_player()

	if player != null and player is Node2D:
		fallback_position = (player as Node2D).global_position

	return GameManager.get_respawn_position(fallback_position)


func delete_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var dir: DirAccess = DirAccess.open("user://")

	if dir == null:
		push_warning("No se ha podido abrir user:// para borrar la partida.")
		return

	var error: Error = dir.remove(SAVE_FILE_NAME)

	if error != OK:
		push_warning("No se ha podido borrar el archivo de guardado.")


func get_player() -> Node:
	var players: Array = get_tree().get_nodes_in_group("player")

	if players.size() > 0:
		return players[0]

	players = get_tree().get_nodes_in_group("Player")

	if players.size() > 0:
		return players[0]

	return null


func play_intro_dialogue_if_needed() -> void:
	if not start_intro_dialogue:
		return

	start_intro_dialogue = false

	await get_tree().process_frame
	await get_tree().process_frame

	if not ResourceLoader.exists(INTRO_DIALOGUE_PATH):
		push_warning("No existe el diálogo inicial: " + INTRO_DIALOGUE_PATH)
		return

	DialogueManager.show_dialogue_balloon(
		load(INTRO_DIALOGUE_PATH),
		INTRO_DIALOGUE_TITLE
	)


func _save_game_at_position(spawn_position: Vector2) -> bool:
	var save_data: Dictionary = {
		"version": 1,
		"scene_path": _get_current_scene_path(),
		"player_position": [spawn_position.x, spawn_position.y],
		"game_manager": GameManager.get_save_data(),
		"player": _get_player_custom_save_data()
	}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("No se ha podido abrir el archivo de guardado: " + SAVE_PATH)
		return false

	file.store_string(JSON.stringify(save_data))
	file.close()

	print("Partida guardada en: ", SAVE_PATH)
	return true


func _read_save_file() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error("No se ha podido leer el archivo de guardado: " + SAVE_PATH)
		return {}

	var text: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var error: Error = json.parse(text)

	if error != OK:
		push_error("Error leyendo JSON de guardado: " + json.get_error_message())
		return {}

	if typeof(json.data) != TYPE_DICTIONARY:
		push_error("El archivo de guardado no contiene un Dictionary válido.")
		return {}

	return json.data


func _get_current_scene_path() -> String:
	if get_tree().current_scene != null:
		var path: String = get_tree().current_scene.scene_file_path

		if path != "":
			return path

	return FIRST_GAME_SCENE


func _get_player_custom_save_data() -> Dictionary:
	var player: Node = get_player()

	if player == null:
		return {}

	if player.has_method("get_save_data"):
		return player.get_save_data()

	return {}


func _apply_pending_player_after_scene_loaded() -> void:
	await get_tree().process_frame
	await get_tree().process_frame

	var player: Node = get_player()

	if player == null:
		is_loading_game = false
		push_warning("No se ha encontrado jugador después de cargar la partida.")
		return

	if player.has_method("load_save_data"):
		player.load_save_data(pending_player_data)

	if has_pending_player_position and player is Node2D:
		(player as Node2D).global_position = pending_player_position

	has_pending_player_position = false
	pending_player_data = {}
	is_loading_game = false
