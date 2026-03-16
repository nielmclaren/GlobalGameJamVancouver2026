class_name StateSynchronizer
extends Node

@export var player: Player

# Player's method for getting the current player state.
var _get_state: Callable

# Player's method for applying the given player state.
var _apply_state: Callable

# Player's method for getting the player input.
var _get_input: Callable

# Player's method for applying the given player input.
var _apply_input: Callable

# True iff this Godot instance is hosting the online multiplayer game (server authority).
var _is_game_host: bool

# True iff the person running this Godot instance is controlling this player.
var _is_local_player: bool

# Buffer player input for game client to play back over position updates received from game host.
var _local_input_buffer: Array[PlayerInput]

# Buffer player input for sending from game client to game host.
var _input_send_buffer: Array[PlayerInput]

# Buffer player input received from game client for replay on the game host.
var _input_receive_buffer: Array[PlayerInput]

# Buffer player state for sending from game host to game client.
var _state_send_buffer: Array[PlayerState]

# Buffer player state received from game host for replay on the game client.
var _state_receive_buffer: Array[PlayerState]

# The message num that will be assigned to the next player input.
var _next_message_num: AutoIncrement = AutoIncrement.new()

# The message num of the latest player input to have been applied on the game host.
var _processed_message_num: int = -1

# Ticks msec when ready was called.
var _ready_ticks: int = 0

@onready var _sync_timer: Timer = %SyncTimer


func setup(
	is_game_host: bool,
	is_local_player: bool,
) -> StateSynchronizer:
	_is_game_host = is_game_host
	_is_local_player = is_local_player

	if _is_game_host:
		_sync_timer.timeout.connect(_host_sync)
	else:
		_sync_timer.timeout.connect(_client_sync)

	if _is_game_host:
		MultiplayerManager.message_received.connect(_game_host_receive_input)
	else:
		MultiplayerManager.message_received.connect(_game_client_receive_state)

	return self


func _ready() -> void:
	_ready_ticks = Time.get_ticks_msec()

	_get_state = player.get_state
	_apply_state = player.apply_state
	_get_input = player.get_input
	_apply_input = player.apply_input


func process_local_player(delta: float) -> void:
	var input: PlayerInput = _get_input.call(delta)
	input.ticks = Time.get_ticks_msec() - _ready_ticks
	input.message_num = _next_message_num.next()

	_apply_input.call(input)

	if _is_game_host:
		var state: PlayerState = _get_state.call()
		state.ticks = Time.get_ticks_msec() - _ready_ticks
		state.message_num = _next_message_num.next()
		_state_send_buffer.append(state)

	else:
		# Send inputs to the game host.
		_input_send_buffer.append(input)

		# Store inputs to replay over the state received from the game host.
		_local_input_buffer.append(input)


func process_remote_player(_delta: float) -> void:
	var now: int = Time.get_ticks_msec() - _ready_ticks
	if _is_game_host:
		# Replay inputs received from the game client.
		_apply_received_inputs(now - Constants.GAME_HOST_TICKS_OFFSET)

		# Send the resulting state to the game client.
		_send_single_state()

	else:
		var latest_state: PlayerState

		var next: Array[PlayerState]
		for state: PlayerState in _state_receive_buffer:
			if state.ticks <= now - Constants.GAME_CLIENT_TICKS_OFFSET:
				latest_state = state
			else:
				next.append(state)
		_state_receive_buffer = next

		if latest_state:
			_apply_state.call(latest_state)


func _apply_received_inputs(ticks: int) -> void:
	var next: Array[PlayerInput]
	for input: PlayerInput in _input_receive_buffer:
		if input.ticks <= ticks:
			_apply_input.call(input)
			_processed_message_num = input.message_num
		else:
			next.append(input)

	_input_receive_buffer = next


func _send_single_state() -> void:
	var state: PlayerState = _get_state.call()
	state.message_num = _processed_message_num

	# Game host should only send one state for the game client's player.
	_state_send_buffer.assign([state])


func process_received_inputs_until(ticks: int) -> Array[PlayerInput]:
	var result: Array[PlayerInput]
	var next: Array[PlayerInput]
	for input: PlayerInput in _input_receive_buffer:
		if input.ticks <= ticks:
			result.append(input)
		else:
			next.append(input)

	_input_receive_buffer = next
	return result


func _host_sync() -> void:
	if !_state_send_buffer.is_empty():
		var message: MultiplayerMessage = MultiplayerMessage.new(get_path(), "state")
		for state: PlayerState in _state_send_buffer:
			message.append_string(state.serialize())
		_state_send_buffer.clear()
		MultiplayerManager.send(message)


func _client_sync() -> void:
	if !_input_send_buffer.is_empty():
		var message: MultiplayerMessage = MultiplayerMessage.new(get_path(), "input")
		for input: PlayerInput in _input_send_buffer:
			message.append_string(input.serialize())
		_input_send_buffer.clear()
		MultiplayerManager.send(message)


func _game_host_receive_input(message: MultiplayerMessage) -> void:
	if !message.matches_path(get_path()):
		return

	if message.name != "input":
		push_error(
			"Game host received unexpected message. Expected 'input'. Got '%s'." % message.name
		)
		return

	for i: int in range(message.arg_size()):
		var input: PlayerInput = PlayerInput.deserialize(message.get_string(i))
		_input_receive_buffer.append(input)


func _game_client_receive_state(message: MultiplayerMessage) -> void:
	if !message.matches_path(get_path()):
		return

	if message.name != "state":
		push_error(
			"Game client received unexpected message. Expected 'state'. Got '%s'." % message.name
		)
		return

	if _is_local_player:
		# Apply the state received from the game host.
		var state: PlayerState = PlayerState.deserialize(message.get_string(0))
		_apply_state.call(state)
		_processed_message_num = state.message_num

		# Replay local inputs that weren't taken into consideration when the game host calculated that state.
		_replay_inputs(state.message_num)

	else:
		# Store the states received from the game host for replay on the game client.
		for i: int in range(message.arg_size()):
			var state: PlayerState = PlayerState.deserialize(message.get_string(i))
			_state_receive_buffer.append(state)


func _replay_inputs(message_num: int) -> void:
	_local_input_buffer = _local_input_buffer.filter(
		func(input: PlayerInput) -> bool: return input.message_num > message_num
	)
	for input: PlayerInput in _local_input_buffer:
		_apply_input.call(input)
