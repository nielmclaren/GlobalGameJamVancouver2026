extends Node

signal connected
signal disconnected
signal room_created(room_id: String)
signal room_gone
signal room_full
signal room_ready
signal partner_left
signal message_received(message: MultiplayerMessage)
signal status_message_changed(status: StatusMessage)

enum StatusMessage { CONNECTING, CONNECTED, PARTNER_DISCONNECTED, DISCONNECTED }

var status_message: StatusMessage = StatusMessage.CONNECTING

var _socket_url: String = "wss://multiplayer.nonexistent.ca:443"
var _socket: WebSocketPeer = WebSocketPeer.new()

var _peer_id: String

var _message_handler: Callable = Callable()


func open() -> void:
	var s: int = _socket.get_ready_state()
	if s != WebSocketPeer.STATE_CLOSED and s != WebSocketPeer.STATE_CLOSING:
		return

	_message_handler = _handle_handshake

	Tracer.trace("Connecting to socket URL.", {"socket_url": _socket_url})
	var err: int = _socket.connect_to_url(_socket_url)
	if err == OK:
		Tracer.trace("Connected.")

		# TODO: Can I wait for the connection itself?
		await get_tree().create_timer(2).timeout

		_set_status_message(StatusMessage.CONNECTED)
		set_process(true)

	else:
		Tracer.trace("Connection failed.")
		_set_status_message(StatusMessage.DISCONNECTED)
		set_process(false)


func is_open() -> bool:
	return _socket.get_ready_state() == WebSocketPeer.STATE_OPEN


func close() -> void:
	var s: int = _socket.get_ready_state()
	if s != WebSocketPeer.STATE_CLOSED and s != WebSocketPeer.STATE_CLOSING:
		Tracer.trace("Closing connection.")
		_socket.close(1000)


func create_room() -> void:
	_message_handler = _handle_create_room
	_send_raw("create_room")


func join_room(room_id: String) -> void:
	_message_handler = _handle_join_room
	_send_raw("join_room:%s" % room_id)


func leave_room() -> void:
	_send_raw("leave_room")


func send(message: MultiplayerMessage) -> void:
	_send_raw(message.serialize())


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(false)


func _process(_delta: float) -> void:
	_socket.poll()
	var state: int = _socket.get_ready_state()

	if state == WebSocketPeer.STATE_OPEN:
		while _socket.get_available_packet_count():
			var packet: PackedByteArray = _socket.get_packet()
			if _socket.was_string_packet():
				var payload: String = packet.get_string_from_utf8()
				if payload == "leave_room":
					_set_status_message(StatusMessage.PARTNER_DISCONNECTED)
					partner_left.emit()
				elif !_message_handler.is_null():
					_message_handler.call(payload)

			else:
				Tracer.warn("Expected string and received binary data. Closing socket.")
				push_warning("Expected string and received binary data. Closing socket.")
				_socket.close(1003)

	elif state == WebSocketPeer.STATE_CLOSING:
		pass

	elif state == WebSocketPeer.STATE_CLOSED:
		var code: int = _socket.get_close_code()
		Tracer.trace("WebSocket closed with code: %d" % code)
		set_process(false)

		_set_status_message(StatusMessage.DISCONNECTED)
		disconnected.emit()


func _exit_tree() -> void:
	_socket.close()


func _send_raw(message: String) -> void:
	if _socket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_set_status_message(StatusMessage.CONNECTED)
		_socket.send_text(message)

	else:
		var code: int = _socket.get_close_code()
		Tracer.warn("Send failed. WebSocket closed with code: %d" % code)
		set_process(false)

		_set_status_message(StatusMessage.DISCONNECTED)
		disconnected.emit()


func _handle_handshake(payload: String) -> void:
	if !RegEx.create_from_string(r"^\d+$").search(payload):
		Tracer.warn("Expected ID string.", {"received": payload})
		push_warning("Expected ID string. instead=%s" % payload)
		set_process(false)
		return

	_peer_id = payload
	_message_handler = Callable()

	connected.emit()


func _handle_create_room(payload: String) -> void:
	if !payload.begins_with("room_created:"):
		Tracer.trace("Expected room_created:<ROOM_ID>.", {"received": payload})
		push_warning("Expected room_created:<ROOM_ID>. Received %s" % payload)
		return

	var room_id: String = payload.split(":")[1]
	Tracer.trace("Created room.", {"room_id": room_id})

	_message_handler = _handle_room_waiting_for_client

	room_created.emit(room_id)


func _handle_join_room(payload: String) -> void:
	if payload == "room_gone":
		room_gone.emit()
		return

	if payload == "room_full":
		room_full.emit()
		return

	if !payload.begins_with("room_joined:"):
		Tracer.trace("Received unexpected message.", {"received": payload})
		push_warning("Received unexpected message %s" % payload)
		return

	var room_id: String = payload.split(":")[1]
	Tracer.trace("Joined room. Room is ready.", {"room_id": room_id})

	_message_handler = _handle_relay

	room_ready.emit()


func _handle_room_waiting_for_client(payload: String) -> void:
	if payload != "room_ready":
		Tracer.trace("Expected room_ready.", {"received": payload})
		push_warning("Expected room_ready. Received %s" % payload)
		return

	Tracer.trace("Client has joined room. Room is ready.")

	_message_handler = _handle_relay

	room_ready.emit()


func _handle_relay(payload: String) -> void:
	message_received.emit(MultiplayerMessage.deserialize(payload))


func _set_status_message(status_message_: StatusMessage) -> void:
	status_message = status_message_
	status_message_changed.emit(status_message)
