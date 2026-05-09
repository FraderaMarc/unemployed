extends Control

@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	continue_button.disabled = not SaveManager.has_save()


func _on_new_game_pressed() -> void:
	SaveManager.new_game()


func _on_continue_pressed() -> void:
	if not SaveManager.continue_game():
		continue_button.disabled = true


func _on_exit_pressed() -> void:
	get_tree().quit()
