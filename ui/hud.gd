class_name Hud
extends CanvasLayer

@onready var score_label0: Label = %ScoreLabel0
@onready var score_label1: Label = %ScoreLabel1

@onready var _score_labels: Array[Label] = [%ScoreLabel0, %ScoreLabel1]


func _ready() -> void:
	set_score(0, 0)
	set_score(1, 0)


func set_score(player_num: int, score: int) -> void:
	_score_labels[player_num].text = "%d Points" % score
