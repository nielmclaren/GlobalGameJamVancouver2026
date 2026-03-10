class_name LocalOnlineScreen
extends Node2D

signal canceled
signal completed(is_online_multiplayer: bool)

var _is_online_pressed: bool = false

@onready var _local_button: Button = %LocalButton
@onready var _online_button: Button = %OnlineButton
@onready var _message_label: Label = %MessageLabel
@onready var _back_button: SmartBackButton = %SmartBackButton


func _ready() -> void:
	MultiplayerManager.connected.connect(_connected)
	MultiplayerManager.disconnected.connect(_disconnected)

	_local_button.pressed.connect(_local_button_pressed)
	_online_button.pressed.connect(_online_button_pressed)
	_back_button.pressed.connect(_back_button_pressed)
	_local_button.grab_focus.call_deferred()

	_message_label.text = ""


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and !event.is_echo():
		canceled.emit()


func _local_button_pressed() -> void:
	completed.emit(false)


func _online_button_pressed() -> void:
	_is_online_pressed = true

	if MultiplayerManager.is_open():
		completed.emit(true)

	else:
		_local_button.disabled = true
		_online_button.disabled = true

		MultiplayerManager.open()

		_message_label.text = "Connecting to server..."


func _connected() -> void:
	if MultiplayerManager.is_open() and _is_online_pressed:
		_message_label.text = "Connected."

		completed.emit(true)


func _disconnected() -> void:
	_local_button.disabled = false

	_message_label.text = "Server is offline."

	await get_tree().create_timer(5).timeout
	_online_button.disabled = false


func _back_button_pressed() -> void:
	canceled.emit()
