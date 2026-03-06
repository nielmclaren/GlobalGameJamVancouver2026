class_name LocalOnlineScreen
extends Node2D

signal canceled
signal completed(is_online_multiplayer: bool)

@onready var _local_button: Button = %LocalButton
@onready var _online_button: Button = %OnlineButton
@onready var _back_button: SmartBackButton = %SmartBackButton


func _ready() -> void:
	_local_button.pressed.connect(_local_button_pressed)
	_online_button.pressed.connect(_online_button_pressed)
	_back_button.pressed.connect(_back_button_pressed)
	_local_button.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and !event.is_echo():
		canceled.emit()


func _local_button_pressed() -> void:
	completed.emit(false)


func _online_button_pressed() -> void:
	completed.emit(true)


func _back_button_pressed() -> void:
	canceled.emit()
