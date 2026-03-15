class_name StateSynchronizer
extends Node

var _get_state: Callable

var _apply_state: Callable

var _apply_input: Callable

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

var _processed_message_num: int


func setup(
	get_state_: Callable, apply_state_: Callable, apply_input_: Callable
) -> StateSynchronizer:
	_get_state = get_state_
	_apply_state = apply_state_
	_apply_input = apply_input_
	return self


func _process(_delta: float) -> void:
	if _local_input_buffer.size() > 300:
		print("_local_input_buffer")
	if _input_send_buffer.size() > 300:
		print("input_send_buffer")
	if _input_receive_buffer.size() > 300:
		print("_input_receive_buffer")
	if _state_send_buffer.size() > 300:
		print("_state_send_buffer")
	if _state_receive_buffer.size() > 300:
		print("_state_receive_buffer")


# TODO
func name_me_please(ticks: int) -> void:
	var next: Array[PlayerInput]
	for input: PlayerInput in _input_receive_buffer:
		if input.ticks <= ticks:
			_apply_input.call(input)
			_processed_message_num = input.message_num
		else:
			next.append(input)

	_input_receive_buffer = next

	var state: PlayerState = _get_state.call()
	state.message_num = _processed_message_num

	# Game host should only send one state for the game client's player.
	_state_send_buffer.assign([state])


func host_send_state(state: PlayerState) -> void:
	_state_send_buffer.append(state)


func client_send_input(input: PlayerInput) -> void:
	_input_send_buffer.append(input)
	_local_input_buffer.append(input)


func host_receive_input(input: PlayerInput) -> void:
	_input_receive_buffer.append(input)


func client_receive_state(state: PlayerState) -> void:
	_state_receive_buffer.append(state)


func apply_inputs_after(message_num: int) -> void:
	_local_input_buffer = _local_input_buffer.filter(
		func(input: PlayerInput) -> bool: return input.message_num > message_num
	)
	for input: PlayerInput in _local_input_buffer:
		_apply_input.call(input)


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


func process_received_states_until(ticks: int) -> Array[PlayerState]:
	var result: Array[PlayerState]
	var next: Array[PlayerState]
	for state: PlayerState in _state_receive_buffer:
		if state.ticks <= ticks:
			result.append(state)
		else:
			next.append(state)

	_state_receive_buffer = next
	return result


func host_sync() -> void:
	if !_state_send_buffer.is_empty():
		var message: MultiplayerMessage = MultiplayerMessage.new(get_parent().get_path(), "state")
		message.append_int(_state_send_buffer.size())
		for state: PlayerState in _state_send_buffer:
			message.append_string(state.serialize())
		_state_send_buffer.clear()
		MultiplayerManager.send(message)


func client_sync() -> void:
	if !_input_send_buffer.is_empty():
		var message: MultiplayerMessage = MultiplayerMessage.new(get_parent().get_path(), "input")
		message.append_int(_input_send_buffer.size())
		for input: PlayerInput in _input_send_buffer:
			message.append_string(input.serialize())
		_input_send_buffer.clear()
		MultiplayerManager.send(message)
