class_name PauseMenu
extends Node2D

signal resume_pressed
signal abandon_pressed
signal credits_pressed
signal exit_pressed
signal fullscreen_pressed

var _is_credits_button_focused: bool = false

@onready var resume_button: Button = %ResumeButton
@onready var abandon_button: Button = %AbandonButton
@onready var credits_button: Button = %CreditsButton
@onready var exit_button: Button = %ExitButton
@onready var fullscreen_button: Button = %FullscreenButton


func _ready() -> void:
	resume_button.pressed.connect(resume_pressed.emit)
	abandon_button.pressed.connect(abandon_pressed.emit)
	credits_button.pressed.connect(credits_pressed.emit)
	exit_button.pressed.connect(exit_pressed.emit)
	fullscreen_button.pressed.connect(fullscreen_pressed.emit)

	visibility_changed.connect(
		func() -> void:
			if visible:
				resume_button.grab_focus()
	)
	get_viewport().gui_focus_changed.connect(_gui_focus_changed)


func focus() -> void:
	if _is_credits_button_focused:
		credits_button.grab_focus()

	else:
		resume_button.grab_focus()


func _gui_focus_changed(node: Control) -> void:
	if is_ancestor_of(node):
		_is_credits_button_focused = node == credits_button
