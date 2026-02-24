class_name LocalOnlineScreen
extends Node2D

signal completed(is_online_multiplayer: bool)

@onready var _local_button: Button = %LocalButton
@onready var _online_button: Button = %OnlineButton


func _ready() -> void:
	_local_button.pressed.connect(_local_button_pressed)
	_online_button.pressed.connect(_online_button_pressed)


func _local_button_pressed() -> void:
	completed.emit(false)


func _online_button_pressed() -> void:
	completed.emit(true)
