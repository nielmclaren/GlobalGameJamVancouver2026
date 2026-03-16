class_name StatusMessageScreen
extends Node2D

signal completed

var message: String

@onready var _message_label: Label = %MessageLabel
@onready var _controller_content: Node2D = %ControllerContent
@onready var _mouse_content: Node2D = %MouseContent
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	Tracer.trace("Status message screen ready.", {"message": message})

	_continue_button.pressed.connect(_continue_button_pressed)

	ControllerIcons.input_type_changed.connect(_input_type_changed)
	_controller_content.visible = (
		ControllerIcons.get_last_input_type() == ControllerIcons.InputType.CONTROLLER
	)
	_mouse_content.visible = (
		ControllerIcons.get_last_input_type() == ControllerIcons.InputType.KEYBOARD_MOUSE
	)

	_message_label.text = message

	_continue_button.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and !event.is_echo():
		_continue_button_pressed()


func _input_type_changed(input_type: ControllerIcons.InputType, _controller: int) -> void:
	_controller_content.visible = input_type == ControllerIcons.InputType.CONTROLLER
	_mouse_content.visible = input_type == ControllerIcons.InputType.KEYBOARD_MOUSE


func _continue_button_pressed() -> void:
	Tracer.trace("Continue.")
	completed.emit()
