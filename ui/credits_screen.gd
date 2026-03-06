class_name CreditsScreen
extends Node2D

signal done_pressed

@onready var _mouse_content: Node2D = %MouseContent
@onready var _controller_content: Node2D = %ControllerContent
@onready var done_button: Button = %DoneButton


func _ready() -> void:
	done_button.pressed.connect(func() -> void: done_pressed.emit())

	visibility_changed.connect(
		func() -> void:
			if visible:
				done_button.grab_focus.call_deferred()
	)

	ControllerIcons.input_type_changed.connect(_input_type_changed)
	_controller_content.visible = (
		ControllerIcons.get_last_input_type() == ControllerIcons.InputType.CONTROLLER
	)
	_mouse_content.visible = (
		ControllerIcons.get_last_input_type() == ControllerIcons.InputType.KEYBOARD_MOUSE
	)


func _input_type_changed(input_type: ControllerIcons.InputType, _controller: int) -> void:
	_controller_content.visible = input_type == ControllerIcons.InputType.CONTROLLER
	_mouse_content.visible = input_type == ControllerIcons.InputType.KEYBOARD_MOUSE
