extends CanvasLayer



@onready var coin_label=$Control/Label

func set_coins(amount):
	coin_label.text=str(amount)
