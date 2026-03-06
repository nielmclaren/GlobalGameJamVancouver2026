class_name WinnerScreen
extends Node2D

signal completed

var winner_player_index: int = -1

# Indicates which mask the winner is wearing.
var winner_color_index: int = -1

# Indicates which mask the loser is wearing.
var loser_color_index: int = -1

@onready var _winner_label0: Label = %WinnerLabel0
@onready var _winner_label1: Label = %WinnerLabel1

@onready var _winner_loser_art: Node2D = %WinnerLoserArt
@onready var _winner_animated_sprite: AnimatedSprite2D = %WinnerAnimatedSprite
@onready var _loser_animated_sprite: AnimatedSprite2D = %LoserAnimatedSprite

@onready var _controller_content: Node2D = %ControllerContent
@onready var _mouse_content: Node2D = %MouseContent
@onready var _continue_button: Button = %ContinueButton


func _ready() -> void:
	Tracer.trace("Show winner.", {"winner": winner_player_index, "loser": 1 - winner_player_index})

	_continue_button.pressed.connect(_continue_button_pressed)

	ControllerIcons.input_type_changed.connect(_input_type_changed)
	_controller_content.visible = (
		ControllerIcons.get_last_input_type() == ControllerIcons.InputType.CONTROLLER
	)
	_mouse_content.visible = (
		ControllerIcons.get_last_input_type() == ControllerIcons.InputType.KEYBOARD_MOUSE
	)

	_ready_artwork()

	_continue_button.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and !event.is_echo():
		_continue_button_pressed()


func _input_type_changed(input_type: ControllerIcons.InputType, _controller: int) -> void:
	_controller_content.visible = input_type == ControllerIcons.InputType.CONTROLLER
	_mouse_content.visible = input_type == ControllerIcons.InputType.KEYBOARD_MOUSE


func _ready_artwork() -> void:
	_winner_label0.visible = winner_player_index == 0
	_winner_label1.visible = winner_player_index == 1

	_winner_loser_art.scale.x = -1 if winner_player_index == 0 else 1

	var winner_form: String = "base"
	if winner_color_index >= 0:
		winner_form = Constants.PLAYER_FORMS[winner_color_index]
	_winner_animated_sprite.play(winner_form)

	var loser_form: String = "base"
	if loser_color_index >= 0:
		loser_form = Constants.PLAYER_FORMS[loser_color_index]
	_loser_animated_sprite.play(loser_form)


func _continue_button_pressed() -> void:
	Tracer.trace("Winner screen: continue button pressed.")
	completed.emit()
