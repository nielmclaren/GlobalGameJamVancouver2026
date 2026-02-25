class_name CharacterSelectionScreen
extends Node2D

signal canceled
signal completed(local_player_index: int)

enum CharacterSelection { NONE = -1, LEFT = 0, RIGHT = 1 }
const HOST_INDEX: int = 0
const CLIENT_INDEX: int = 1

var is_game_host: bool = false
var is_online_multiplayer: bool = false

# Controller can have left character -1, right character 1, or no character 0.
var _state_character_selections: Array[CharacterSelection] = [
	CharacterSelection.NONE, CharacterSelection.NONE
]
var _state_readys: Array[bool] = [false, false]

@onready var _controllers: Array[CharacterSelectionController] = [%Controller0, %Controller1]
@onready var _controller_markers: Array[Marker2D] = [%ControllerMarker0, %ControllerMarker1]
@onready var _character_markers: Array[Marker2D] = [%CharacterMarker0, %CharacterMarker1]
@onready var _confirm_nodes: Array[Node2D] = [%Confirm0, %Confirm1]
@onready var _ready_nodes: Array[Node2D] = [%Ready0, %Ready1]
@onready var _other_ready_nodes: Array[Node2D] = [%OtherReady0, %OtherReady1]
@onready var _animation: AnimationPlayer = %AnimationPlayer
@onready var _back_button: Button = %BackButton


func _ready() -> void:
	_confirm_nodes[0].hide()
	_confirm_nodes[1].hide()
	_ready_nodes[0].hide()
	_ready_nodes[1].hide()
	_other_ready_nodes[0].hide()
	_other_ready_nodes[1].hide()

	_back_button.pressed.connect(_back_button_pressed)

	MultiplayerManager.message_received.connect(_message_received)

	if is_game_host:
		_game_host_send_state()

	_update()


func _update() -> void:
	_update_player(HOST_INDEX)
	_update_player(CLIENT_INDEX)

	_update_ready_prompts()

	if not false in _state_readys:
		_animation.play("ready")
	else:
		_animation.play("RESET")

	if is_game_host:
		_game_host_send_state()


func _input(event: InputEvent) -> void:
	if is_online_multiplayer:
		_online_multiplayer_input(event)

	else:
		_local_multiplayer_input(event)


func _online_multiplayer_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left"):
		if is_game_host:
			if !_state_readys[HOST_INDEX]:
				_apply_input(HOST_INDEX, CLIENT_INDEX, "move_left")
				_update()

		else:
			if !_state_readys[CLIENT_INDEX]:
				_game_client_send_input("move_left")

	elif event.is_action_pressed("move_right"):
		if is_game_host:
			if !_state_readys[HOST_INDEX]:
				_apply_input(HOST_INDEX, CLIENT_INDEX, "move_right")
				_update()

		else:
			if !_state_readys[CLIENT_INDEX]:
				_game_client_send_input("move_right")

	elif event.is_action_pressed("ui_accept"):
		if is_game_host:
			_apply_input(HOST_INDEX, CLIENT_INDEX, "ui_accept")
			_update()

		else:
			if _state_character_selections[CLIENT_INDEX] != CharacterSelection.NONE:
				_game_client_send_input("ui_accept")

	elif event.is_action_pressed("ui_cancel"):
		if is_game_host:
			_apply_input(HOST_INDEX, CLIENT_INDEX, "ui_cancel")
			_update()

		else:
			if _state_character_selections[CLIENT_INDEX] != CharacterSelection.NONE:
				_game_client_send_input("ui_cancel")


func _local_multiplayer_input(event: InputEvent) -> void:
	if event.is_action_pressed("move_left0"):
		if !_state_readys[HOST_INDEX]:
			_apply_input(HOST_INDEX, CLIENT_INDEX, "move_left")
			_update()

	if event.is_action_pressed("move_left1"):
		if !_state_readys[CLIENT_INDEX]:
			_apply_input(CLIENT_INDEX, HOST_INDEX, "move_left")
			_update()

	if event.is_action_pressed("move_right0"):
		if !_state_readys[HOST_INDEX]:
			_apply_input(HOST_INDEX, CLIENT_INDEX, "move_right")
			_update()

	if event.is_action_pressed("move_right1"):
		if !_state_readys[CLIENT_INDEX]:
			_apply_input(CLIENT_INDEX, HOST_INDEX, "move_right")
			_update()

	if event.is_action_pressed("ui_accept0"):
		_apply_input(HOST_INDEX, CLIENT_INDEX, "ui_accept")
		_update()

	elif event.is_action_pressed("ui_accept1"):
		_apply_input(CLIENT_INDEX, HOST_INDEX, "ui_accept")
		_update()

	if event.is_action_pressed("ui_cancel0"):
		_apply_input(HOST_INDEX, CLIENT_INDEX, "ui_cancel")
		_update()

	if event.is_action_pressed("ui_cancel1"):
		_apply_input(CLIENT_INDEX, HOST_INDEX, "ui_cancel")
		_update()


func _update_player(index: int) -> void:
	var character_selection: CharacterSelection = _state_character_selections[index]
	if character_selection == CharacterSelection.NONE:
		_controllers[index].position = _controller_markers[index].position

	else:
		_controllers[index].position = _character_markers[character_selection].position


func _update_ready_prompts() -> void:
	for selection: CharacterSelection in [CharacterSelection.LEFT, CharacterSelection.RIGHT]:
		_confirm_nodes[selection].visible = (
			(
				(is_game_host or !is_online_multiplayer)
				and _state_character_selections[HOST_INDEX] == selection
				and !_state_readys[HOST_INDEX]
			)
			or (
				(!is_game_host or !is_online_multiplayer)
				and _state_character_selections[CLIENT_INDEX] == selection
				and !_state_readys[CLIENT_INDEX]
			)
		)
		_ready_nodes[selection].visible = (
			(
				(is_game_host or !is_online_multiplayer)
				and _state_character_selections[HOST_INDEX] == selection
				and _state_readys[HOST_INDEX]
			)
			or (
				(!is_game_host or !is_online_multiplayer)
				and _state_character_selections[CLIENT_INDEX] == selection
				and _state_readys[CLIENT_INDEX]
			)
		)
		_other_ready_nodes[selection].visible = (
			(
				(is_game_host or !is_online_multiplayer)
				and _state_character_selections[CLIENT_INDEX] == selection
				and _state_readys[CLIENT_INDEX]
			)
			or (
				(!is_game_host or !is_online_multiplayer)
				and _state_character_selections[HOST_INDEX] == selection
				and _state_readys[HOST_INDEX]
			)
		)


func _apply_input(player: int, other_player: int, action: String) -> void:
	match action:
		"move_left":
			_move_character_selection(player, other_player, -1)
		"move_right":
			_move_character_selection(player, other_player, 1)
		"ui_accept":
			_confirm_character_selection(player, true)
		"ui_cancel":
			if _state_readys[player]:
				_confirm_character_selection(player, false)


func _move_character_selection(player: int, other_player: int, direction: int) -> void:
	if direction < 0:
		if (
			_state_character_selections[player] == CharacterSelection.NONE
			and _state_character_selections[other_player] != CharacterSelection.LEFT
		):
			_state_character_selections[player] = CharacterSelection.LEFT

		elif _state_character_selections[player] == CharacterSelection.RIGHT:
			_state_character_selections[player] = CharacterSelection.NONE

	elif direction > 0:
		if (
			_state_character_selections[player] == CharacterSelection.NONE
			and _state_character_selections[other_player] != CharacterSelection.RIGHT
		):
			_state_character_selections[player] = CharacterSelection.RIGHT

		elif _state_character_selections[player] == CharacterSelection.LEFT:
			_state_character_selections[player] = CharacterSelection.NONE


func _confirm_character_selection(player: int, value: bool) -> void:
	if _state_character_selections[player] != CharacterSelection.NONE:
		_state_readys[player] = value


func _message_received(message: MultiplayerMessage) -> void:
	if is_game_host:
		_game_host_receive_input(message)

	else:
		_game_client_receive_state(message)


func _game_client_send_input(action: String) -> void:
	MultiplayerManager.send(MultiplayerMessage.new(get_path(), "input").append_string(action))


func _game_host_receive_input(message: MultiplayerMessage) -> void:
	if !message.matches_path(get_path()):
		return

	if message.name != "input":
		push_error("Game host received message that wasn't input.")
		return

	_apply_input(CLIENT_INDEX, HOST_INDEX, message.get_string(0))
	_update()


func _game_host_send_state() -> void:
	MultiplayerManager.send(
		(
			MultiplayerMessage
			. new(get_path(), "state")
			. append_int(_state_character_selections[HOST_INDEX])
			. append_bool(_state_readys[HOST_INDEX])
			. append_int(_state_character_selections[CLIENT_INDEX])
			. append_bool(_state_readys[CLIENT_INDEX])
		)
	)


func _game_client_receive_state(message: MultiplayerMessage) -> void:
	if !message.matches_path(get_path()):
		return

	if message.name != "state":
		push_error("Game client received message that wasn't state.")
		return

	_state_character_selections[HOST_INDEX] = message.get_int(0) as CharacterSelection
	_state_readys[HOST_INDEX] = message.get_int(1) > 0
	_state_character_selections[CLIENT_INDEX] = message.get_int(2) as CharacterSelection
	_state_readys[CLIENT_INDEX] = message.get_int(3) > 0
	_update()


func _emit_completed() -> void:
	completed.emit(
		(
			0
			if is_game_host and _state_character_selections[HOST_INDEX] == CharacterSelection.LEFT
			else 1
		)
	)


func _back_button_pressed() -> void:
	if is_online_multiplayer:
		MultiplayerManager.leave_room()

	canceled.emit()
