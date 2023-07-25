extends CanvasLayer

class_name UI

@onready var center_container = $MarginContainer/CenterContainer
@onready var life_count_label = %LifeCountLabel
@onready var game_score_label = %GameScoreLabel
@onready var game_label = %GameLabel


func set_lifes(lifes):
	life_count_label.text = "%d up" % lifes
	if lifes == 0: 
		game_lost()

func set_score(score):
	game_score_label.text = "SCORE: %d" % score

func game_lost():
	game_label.text = "Game lost"
	center_container.show()

func game_won():
	game_label.text = "Game won"
	center_container.show()
