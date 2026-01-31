class_name PauseMenu
extends Node2D

@onready var resume_button: Button = %ResumeButton
@onready var abandon_button: Button = %AbandonButton
@onready var credits_button: Button = %CreditsButton
@onready var exit_button: Button = %ExitButton
@onready var fullscreen_button: Button = %FullscreenButton

signal resume_pressed
signal abandon_pressed
signal credits_pressed
signal exit_pressed
signal fullscreen_pressed


func _ready() -> void:
	resume_button.pressed.connect(resume_pressed.emit)
	abandon_button.pressed.connect(abandon_pressed.emit)
	credits_button.pressed.connect(credits_pressed.emit)
	exit_button.pressed.connect(exit_pressed.emit)
	fullscreen_button.pressed.connect(fullscreen_pressed.emit)
