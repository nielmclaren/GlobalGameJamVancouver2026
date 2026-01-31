class_name CreditsScreen
extends Node2D

@onready var done_button: Button = %DoneButton

signal done_pressed


func _ready() -> void:
	done_button.pressed.connect(func() -> void: done_pressed.emit())
