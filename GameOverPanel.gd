extends Panel
class_name GameOverPanel

@onready var label: Label = $GameOverLabel

func _ready() -> void:
	visible = false


func show_game_over(final_score: int) -> void:
	label.text = "GAME OVER\nScore: %d\nPress R to restart" % final_score
	visible = true


func hide_game_over() -> void:
	visible = false
