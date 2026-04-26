extends Node

signal skillcoins_changed(total)
signal skill_tree_unlocked

var skillcoins: int = 0
var llapis: bool = false
var paper: bool = false
var skill_tree_opened_once: bool = false
var first_skill_unlocked: bool = false

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
