class_name HostJoinScreen
extends Node2D

signal canceled
signal completed(is_game_host: bool)

@onready var _host_code_input: LineEdit = %HostCodeInput
@onready var _host_button: Button = %HostButton
@onready var _host_cancel_button: Button = %HostCancelButton
@onready var _host_disable_mask: ColorRect = %HostDisableMask
@onready var _join_code_input: LineEdit = %JoinCodeInput
@onready var _join_button: Button = %JoinButton
@onready var _join_disable_mask: ColorRect = %JoinDisableMask
@onready var _join_error_label: Label = %JoinErrorLabel
@onready var _back_button: Button = %BackButton

var _is_game_host: bool = false


func _ready() -> void:
	MultiplayerManager.room_gone.connect(_room_gone)
	MultiplayerManager.room_full.connect(_room_full)
	MultiplayerManager.room_ready.connect(_room_ready)

	_host_disable_mask.hide()
	_join_disable_mask.hide()

	_host_code_input.hide()
	_host_cancel_button.hide()

	_host_button.pressed.connect(_host_button_pressed)
	_host_cancel_button.pressed.connect(_host_cancel_button_pressed)

	_join_code_input.text_changed.connect(_join_code_changed)
	_join_code_input.text_submitted.connect(_join_code_submitted)
	_join_button.pressed.connect(_join_code_submitted)

	_join_error_label.text = ""

	_back_button.pressed.connect(canceled.emit)

	_host_button.grab_focus.call_deferred()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		canceled.emit()


func _host_button_pressed() -> void:
	_enable_host_ui(true, false, true)
	_enable_join_ui(false, false)
	_clear_error()

	_is_game_host = true

	MultiplayerManager.room_created.connect(_room_created)
	MultiplayerManager.create_room()


func _host_cancel_button_pressed() -> void:
	_enable_host_ui(true, true, false)
	_enable_join_ui(true, true)
	_clear_error()


func _room_created(room_id: String) -> void:
	MultiplayerManager.room_created.disconnect(_room_created)

	_host_code_input.text = room_id
	_host_code_input.show()


func _join_code_changed(_new_text: String) -> void:
	_clear_error()


func _join_code_submitted(_new_text: String = "") -> void:
	_enable_host_ui(false, false, false)
	_enable_join_ui(true, false)
	_clear_error()

	var room_id: String = RegEx.create_from_string(r"\W").sub(_join_code_input.text, "", true)
	if room_id.length() != 5:  # Expected room code size.
		_show_error("Bad room code.")
		_enable_host_ui(true, true, false)
		_enable_join_ui(true, true)
		return

	room_id = room_id.to_upper()

	_is_game_host = false

	MultiplayerManager.join_room(room_id)


func _room_gone() -> void:
	_show_error("The room does not exist.")
	_enable_host_ui(true, true, false)
	_enable_join_ui(true, true)


func _room_full() -> void:
	_show_error("The room is full.")
	_enable_host_ui(true, true, false)
	_enable_join_ui(true, true)


func _room_ready() -> void:
	completed.emit(_is_game_host)


func _show_error(message: String) -> void:
	_join_error_label.text = message


func _clear_error() -> void:
	_show_error("")


func _enable_host_ui(show_ui: bool, enable_ui: bool, is_already_hosting: bool) -> void:
	_host_disable_mask.visible = !show_ui
	_host_button.disabled = !enable_ui

	_host_button.visible = !is_already_hosting
	_host_cancel_button.visible = is_already_hosting

	if !is_already_hosting:
		_host_code_input.text = ""


func _enable_join_ui(show_ui: bool, enable_ui: bool) -> void:
	_join_disable_mask.visible = !show_ui
	_join_code_input.editable = enable_ui
	_join_button.disabled = !enable_ui
