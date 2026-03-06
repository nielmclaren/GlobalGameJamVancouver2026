class_name SmartBackButton
extends Node2D

signal pressed

@onready var _controller_content: Node2D = %ControllerContent
@onready var _mouse_content: Node2D = %MouseContent
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_back_button.pressed.connect(pressed.emit)

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
