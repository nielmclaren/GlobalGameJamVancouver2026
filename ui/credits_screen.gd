class_name CreditsScreen
extends Node2D

signal done_pressed

@onready var done_button: Button = %DoneButton


func _ready() -> void:
	done_button.pressed.connect(func() -> void: done_pressed.emit())

	visibility_changed.connect(
		func() -> void:
			if visible:
				done_button.grab_focus.call_deferred()
	)
