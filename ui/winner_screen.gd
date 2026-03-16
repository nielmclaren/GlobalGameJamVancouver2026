class_name WinnerScreen
extends Node2D

signal completed
signal canceled

const PLAYER0: int = 0
const PLAYER1: int = 1

var is_online_multiplayer: bool = false
var is_game_host: bool = false
var local_player_index: int = -1

var winner_player_index: int = -1

# Indicates which mask the winner is wearing.
var winner_color_index: int = -1

# Indicates which mask the loser is wearing.
var loser_color_index: int = -1

var _state_readys: Array[bool] = [false, false]

@onready var _winner_label0: Label = %WinnerLabel0
@onready var _winner_label1: Label = %WinnerLabel1

@onready var _winner_loser_art: Node2D = %WinnerLoserArt
@onready var _winner_animated_sprite: AnimatedSprite2D = %WinnerAnimatedSprite
@onready var _loser_animated_sprite: AnimatedSprite2D = %LoserAnimatedSprite

@onready var _confirm_nodes: Array[Node2D] = [%Confirm0, %Confirm1]
@onready var _confirm_icon_sprites: Array[Sprite2D] = [%ConfirmIconSprite0, %ConfirmIconSprite1]
@onready var _ready_nodes: Array[Node2D] = [%Ready0, %Ready1]
@onready var _other_ready_nodes: Array[Node2D] = [%OtherReady0, %OtherReady1]
@onready var _animation: AnimationPlayer = %AnimationPlayer
@onready var _back_button: SmartBackButton = %SmartBackButton


func _ready() -> void:
	Tracer.trace(
		"Winner screen ready.", {"winner": winner_player_index, "loser": 1 - winner_player_index}
	)

	_confirm_nodes[PLAYER0].hide()
	_confirm_nodes[PLAYER1].hide()
	_ready_nodes[PLAYER0].hide()
	_ready_nodes[PLAYER1].hide()
	_other_ready_nodes[PLAYER0].hide()
	_other_ready_nodes[PLAYER1].hide()

	_back_button.pressed.connect(_back_button_pressed)

	MultiplayerManager.message_received.connect(_message_received)

	_ready_artwork()
	_update()

	if is_game_host:
		_game_host_send_state()


func _input(event: InputEvent) -> void:
	if is_online_multiplayer:
		_online_multiplayer_input(event)

	else:
		_local_multiplayer_input(event)


func _online_multiplayer_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept") and !event.is_echo():
		if is_game_host:
			_apply_input(local_player_index, "ui_accept")
			_update()

		else:
			_game_client_send_input("ui_accept")

	if event.is_action_pressed("ui_cancel") and !event.is_echo():
		if is_game_host:
			if _state_readys[local_player_index]:
				_apply_input(local_player_index, "ui_cancel")
				_update()
			else:
				_back_button_pressed()

		else:
			if _state_readys[local_player_index]:
				_game_client_send_input("ui_cancel")
			else:
				_back_button_pressed()


func _local_multiplayer_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept0") and !event.is_echo():
		_apply_input(PLAYER0, "ui_accept")
		_update()

	if event.is_action_pressed("ui_accept1") and !event.is_echo():
		_apply_input(PLAYER1, "ui_accept")
		_update()

	if event.is_action_pressed("ui_cancel0") and !event.is_echo():
		if _state_readys[PLAYER0]:
			_apply_input(PLAYER0, "ui_cancel")
			_update()
		else:
			_back_button_pressed()

	elif event.is_action_pressed("ui_cancel1") and !event.is_echo():
		if _state_readys[PLAYER1]:
			_apply_input(PLAYER1, "ui_cancel")
			_update()
		else:
			_back_button_pressed()

	elif event.is_action_pressed("ui_cancel") and !event.is_echo():
		if _state_readys[PLAYER0] or _state_readys[PLAYER1]:
			# On keyboard both players share a cancel button so just reset if either presses cancel.
			_state_readys[PLAYER0] = false
			_state_readys[PLAYER1] = false
			_update()

		else:
			_back_button_pressed()


func _ready_artwork() -> void:
	_winner_label0.visible = winner_player_index == PLAYER0
	_winner_label1.visible = winner_player_index == PLAYER1

	_winner_loser_art.scale.x = -1 if winner_player_index == PLAYER0 else 1

	var winner_form: String = "base"
	if winner_color_index >= 0:
		winner_form = Constants.PLAYER_FORMS[winner_color_index]
	_winner_animated_sprite.play(winner_form)

	var loser_form: String = "base"
	if loser_color_index >= 0:
		loser_form = Constants.PLAYER_FORMS[loser_color_index]
	_loser_animated_sprite.play(loser_form)


func _update() -> void:
	_update_ready_prompts()

	if not false in _state_readys:
		_animation.play("ready")
	else:
		_animation.play("RESET")

	if is_game_host:
		_game_host_send_state()


func _update_ready_prompts() -> void:
	if is_online_multiplayer:
		_confirm_nodes[local_player_index].visible = !_state_readys[local_player_index]
		_ready_nodes[local_player_index].visible = _state_readys[local_player_index]
		_other_ready_nodes[1 - local_player_index].visible = _state_readys[1 - local_player_index]

	for player_index: int in [PLAYER0, PLAYER1]:
		if !is_online_multiplayer:
			_confirm_nodes[player_index].visible = !_state_readys[player_index]
			_ready_nodes[player_index].visible = _state_readys[player_index]
			_other_ready_nodes[player_index].visible = false

		# For online multiplayer, confirm button is always "ui_accept".
		# For local multiplayer, confirm button depends on the player (space or enter key).
		if _confirm_nodes[player_index].visible:
			var sprite: Sprite2D = _confirm_icon_sprites[player_index]
			var texture: ControllerIconTexture = sprite.texture
			if is_online_multiplayer:
				texture.path = "ui_accept"
			else:
				texture.path = "ui_accept%d" % player_index


func _apply_input(player_index: int, action: String) -> void:
	match action:
		"ui_accept":
			_state_readys[player_index] = true

		"ui_cancel":
			_state_readys[player_index] = false


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

	_apply_input(1 - local_player_index, message.get_string(0))
	_update()


func _game_host_send_state() -> void:
	MultiplayerManager.send(
		MultiplayerMessage.new(get_path(), "state").append_bool(_state_readys[PLAYER0]).append_bool(
			_state_readys[PLAYER1]
		)
	)


func _game_client_receive_state(message: MultiplayerMessage) -> void:
	if !message.matches_path(get_path()):
		return

	if message.name != "state":
		push_error("Game client received message that wasn't state.")
		return

	_state_readys[PLAYER0] = message.get_bool(0)
	_state_readys[PLAYER1] = message.get_bool(1)
	_update()


func _emit_completed() -> void:
	completed.emit()


func _back_button_pressed() -> void:
	Tracer.trace("Canceled.")

	if is_online_multiplayer:
		MultiplayerManager.leave_room()

	canceled.emit()
