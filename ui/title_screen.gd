class_name TitleScreen
extends Node2D

signal play_pressed
signal credits_pressed
signal exit_pressed
signal fullscreen_pressed

@onready var play_button: Button = %PlayButton
@onready var credits_button: Button = %CreditsButton
@onready var exit_button: Button = %ExitButton
@onready var fullscreen_button: Button = %FullscreenButton


func _ready() -> void:
	play_button.pressed.connect(_play_button_pressed)
	credits_button.pressed.connect(_credits_button_pressed)
	exit_button.pressed.connect(exit_pressed.emit)
	fullscreen_button.pressed.connect(fullscreen_pressed.emit)

	if TitleScreenStore.is_credits_button_focused:
		credits_button.grab_focus.call_deferred()
	else:
		play_button.grab_focus.call_deferred()


func _play_button_pressed() -> void:
	TitleScreenStore.is_credits_button_focused = false
	play_pressed.emit()


func _credits_button_pressed() -> void:
	TitleScreenStore.is_credits_button_focused = true
	credits_pressed.emit()
