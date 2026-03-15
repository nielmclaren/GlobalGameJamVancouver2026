class_name Player
extends CharacterBody2D

# Emitted when the player reveals themselves, e.g., by attacking.
signal unmasked

# Emitted when the player goes back into hiding, e.g., after attack.
signal masked

# Emitted when player gets hit.
signal hitted

const SPEED: float = 20000

# The number of player inputs to store.
const INPUT_BUFFER_SIZE: int = 120

var is_online_multiplayer: bool = false
var is_game_host: bool = false
var is_local_player: bool = false

var player_index: int = 0
var device_index: int = 0

var is_stunned: bool = false
var is_stealthed: bool = false:
	get():
		return is_stealthed
	set(v):
		if v != is_stealthed:
			is_stealthed = v
			if is_stealthed:
				_stealth_animation.play("stealth")
			else:
				_stealth_animation.play("destealth")

var color_index: int = -1
var score: int = 0

var _game: Game
var _direction: Vector2
var _prev_direction: Vector2
var _direction_y: int
var _hit_direction: Vector2
var _is_moved_after_hit: bool = true

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

@onready var _art: Node2D = %Art
@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _crown_animated_sprite: AnimatedSprite2D = %CrownAnimatedSprite
@onready var _back_crown_animated_sprite: AnimatedSprite2D = %BackCrownAnimatedSprite
@onready var _front_crown_animated_sprite: AnimatedSprite2D = %FrontCrownAnimatedSprite
@onready var _crown_drop_particles: CPUParticles2D = %CrownDropParticles
@onready var _weapon_animated_sprite: AnimatedSprite2D = %WeaponAnimatedSprite
@onready var _attack_area: Area2D = %AttackArea
@onready var _animation: AnimationPlayer = %AnimationPlayer
@onready var _stealth_animation: AnimationPlayer = %StealthAnimationPlayer
@onready var _weapon: Node2D = %Weapon
@onready var _weapon_sound: AudioStreamPlayer2D = %WeaponSound
@onready var _attack_timer: Timer = %AttackTimer
@onready var _hit_timer: Timer = %HitTimer
@onready var _sync_timer: Timer = %SyncTimer


func _ready() -> void:
	_ready_ticks = Time.get_ticks_msec()

	_attack_area.body_entered.connect(_attack_area_body_entered)
	_weapon_animated_sprite.play("weapon%d" % player_index)

	_crown_animated_sprite.hide()
	_front_crown_animated_sprite.hide()
	_back_crown_animated_sprite.hide()

	_attack_timer.timeout.connect(_attack_timeout)
	_hit_timer.timeout.connect(_hit_timeout)

	MultiplayerManager.message_received.connect(_message_received)

	if is_online_multiplayer:
		_sync_timer.timeout.connect(_sync)
		_sync_timer.start()


func _physics_process(delta: float) -> void:
	if is_online_multiplayer:
		_physics_process_online_multiplayer(delta)

	else:
		_physics_process_local_multiplayer(delta)


func _physics_process_online_multiplayer(delta: float) -> void:
	var now: int = Time.get_ticks_msec() - _ready_ticks
	if is_local_player:
		if is_stunned:
			return

		_direction = _get_input_vector()
		if !_direction.is_zero_approx():
			_is_moved_after_hit = true

		if _direction.length_squared() > 0 or _prev_direction.length_squared() > 0:
			_prev_direction = _direction

			var input: PlayerInput = _get_input(delta)
			_apply_input(input)
			_position_changed()

			if is_game_host:
				var state: PlayerState = PlayerState.new()
				state.direction = _direction
				state.position = position
				state.color_index = color_index
				state.ticks = now
				state.message_num = _next_message_num.next()

				_state_send_buffer.append(state)

			else:
				_input_send_buffer.append(input)

				_local_input_buffer.append(input)
				while _local_input_buffer.size() > INPUT_BUFFER_SIZE:
					_local_input_buffer.pop_front()

	else:
		var prev_position: Vector2 = position

		if is_game_host:
			for received_input: PlayerInput in _input_receive_buffer:
				if received_input.ticks <= now - Constants.GAME_HOST_TICKS_OFFSET:
					_apply_input(received_input)
					_processed_message_num = received_input.message_num

			_input_receive_buffer.assign(
				_input_receive_buffer.filter(
					PlayerInput.filter_after(now - Constants.GAME_HOST_TICKS_OFFSET)
				)
			)
			_position_changed()

			var state: PlayerState = PlayerState.new()
			state.direction = _direction
			state.position = position
			state.color_index = color_index
			state.ticks = now
			state.message_num = _processed_message_num

			# Game host should only send one state for the game client's player.
			_state_send_buffer = [state]

		else:
			for received_state: PlayerState in _state_receive_buffer:
				if received_state.ticks <= now - Constants.GAME_CLIENT_TICKS_OFFSET:
					_direction = received_state.direction
					position = received_state.position
					color_index = received_state.color_index
					_processed_message_num = received_state.message_num

			_state_receive_buffer.assign(
				_state_receive_buffer.filter(
					PlayerState.filter_after(now - Constants.GAME_CLIENT_TICKS_OFFSET)
				)
			)
			_position_changed()

		if prev_position != position:
			_is_moved_after_hit = true


func _physics_process_local_multiplayer(delta: float) -> void:
	if is_stunned:
		return

	_direction = _get_input_vector()
	if !_direction.is_zero_approx():
		_is_moved_after_hit = true

	if _direction.length_squared() > 0 or _prev_direction.length_squared() > 0:
		_prev_direction = _direction

		var input: PlayerInput = _get_input(delta)
		_apply_input(input)
		_position_changed()


func _process(_delta: float) -> void:
	if !_direction.is_zero_approx():
		_weapon.global_rotation = _direction.angle()

		if !is_zero_approx(_direction.y) and abs(_direction.y) > abs(_direction.x):
			_direction_y = sign(_direction.y)
		elif !is_zero_approx(_direction.x):
			_direction_y = 0

		if !is_zero_approx(_direction.x):
			_art.scale.x = sign(_direction.x)

	# Hit recovery should override controller direction.
	if _is_hit_recovery():
		if !is_zero_approx(_hit_direction.x):
			_art.scale.x = sign(_hit_direction.x)

	if _is_moved_after_hit:
		# Hit recovery handles its own animation. Everything else handled here.
		var target_animation: String = _get_animation(_direction_y)
		if _animated_sprite.animation != target_animation:
			_animated_sprite.play(target_animation)

	_update_crown()


func _get_animation(direction_y: int) -> String:
	var player_form: String = _get_player_form(color_index)

	var result: String
	var is_idle: bool = _direction.is_zero_approx()
	if is_idle:
		result = player_form + "_idle"
	else:
		result = player_form + "_walk"

	if direction_y < 0:
		result += "_back"
	elif direction_y > 0:
		result += "_front"

	return result


func _get_player_form(mask_index: int) -> String:
	if mask_index >= 0:
		return Constants.PLAYER_FORMS[mask_index]
	return "base"


func _update_crown() -> void:
	_crown_animated_sprite.hide()
	_front_crown_animated_sprite.hide()
	_back_crown_animated_sprite.hide()

	if score > 0:
		var crown_sprite: AnimatedSprite2D = _crown_animated_sprite
		if _direction_y < 0:
			crown_sprite = _back_crown_animated_sprite
			_back_crown_animated_sprite.show()

		elif _direction_y > 0:
			crown_sprite = _front_crown_animated_sprite
			_front_crown_animated_sprite.show()

		else:
			crown_sprite = _crown_animated_sprite
			_crown_animated_sprite.show()

		if _direction.is_zero_approx():
			crown_sprite.play("idle")
		else:
			crown_sprite.play("walk")


func setup(game: Game) -> Player:
	_game = game
	return self


func take_hit(attacker_position: Vector2) -> void:
	is_stunned = true
	_unmask()

	_hit_direction = attacker_position - global_position

	_hit_timer.start()
	_is_moved_after_hit = false

	if _animation.current_animation == "hit":
		_animation.seek(0)
	_animation.play("hit")

	var animation_key: String = _get_player_form(color_index) + "_hit"
	if _animated_sprite.animation == animation_key:
		_animated_sprite.stop()
	_animated_sprite.play(animation_key)

	if score > 0:
		_crown_drop_particles.amount = score
		_crown_drop_particles.restart()

	hitted.emit()


func _is_hit_recovery() -> bool:
	return !_hit_timer.is_stopped()


func _hit_timeout() -> void:
	is_stunned = false
	_mask()


func _get_input(delta: float) -> PlayerInput:
	var result: PlayerInput = PlayerInput.new()
	result.direction = _direction
	result.delta = delta
	result.ticks = Time.get_ticks_msec() - _ready_ticks
	result.message_num = _next_message_num.next()
	return result


func _apply_input(input: PlayerInput) -> void:
	_direction = input.direction
	if !input.direction.is_zero_approx():
		velocity = input.direction * SPEED * input.delta
		move_and_slide()


func _position_changed() -> void:
	is_stealthed = _game.is_in_stealth_tile(self)


func _attack_area_body_entered(body: Node2D) -> void:
	if body is Player and body != self:
		_try_attack()


func _get_input_vector() -> Vector2:
	var suffix: String = ""
	if !is_online_multiplayer:
		suffix = str(device_index)
	return Input.get_vector(
		"move_left%s" % suffix,
		"move_right%s" % suffix,
		"move_up%s" % suffix,
		"move_down%s" % suffix
	)


func _try_attack() -> void:
	if _animation.is_playing():
		return

	var bodies: Array[Node2D] = _attack_area.get_overlapping_bodies()
	for body: Node2D in bodies:
		if body is Player and body != self:
			var player: Player = body
			_perform_attack(player)
			break


func _perform_attack(victim: Player) -> void:
	victim.take_hit(global_position)

	_animation.play("attack")
	_weapon_sound.play()

	_attack_timer.start()
	is_stunned = true
	_unmask()


func _attack_timeout() -> void:
	is_stunned = false
	_mask()


func _unmask() -> void:
	unmasked.emit()


func _mask() -> void:
	masked.emit()


func _activate_stealth_mode() -> void:
	_set_stealth_mode(true)


func _deactivate_stealth_mode() -> void:
	_set_stealth_mode(false)


func _set_stealth_mode(v: bool) -> void:
	set_collision_layer_value(Constants.COLLISION_LAYER, !v)
	set_collision_mask_value(Constants.COLLISION_LAYER, !v)
	set_collision_layer_value(Constants.ATTACK_LAYER, !v)
	set_collision_mask_value(Constants.ATTACK_LAYER, !v)
	_attack_area.monitoring = !v
	_attack_area.monitorable = !v


func _message_received(message: MultiplayerMessage) -> void:
	if is_game_host:
		_game_host_receive_input(message)

	else:
		_game_client_receive_state(message)


func _game_host_receive_input(message: MultiplayerMessage) -> void:
	if !message.matches_path(get_path()):
		return

	if message.name != "input":
		push_error(
			"Game host received unexpected message. Expected 'input'. Got '%s'." % message.name
		)
		return

	var num_inputs: int = message.get_int(0)
	for i: int in range(num_inputs):
		var input: PlayerInput = PlayerInput.deserialize(message.get_string(i + 1))
		_input_receive_buffer.append(input)


func _sync() -> void:
	if is_game_host:
		if !_state_send_buffer.is_empty():
			var message: MultiplayerMessage = MultiplayerMessage.new(get_path(), "state")
			message.append_int(_state_send_buffer.size())
			for state: PlayerState in _state_send_buffer:
				message.append_string(state.serialize())
			_state_send_buffer.clear()
			MultiplayerManager.send(message)

	else:
		if !_input_send_buffer.is_empty():
			var message: MultiplayerMessage = MultiplayerMessage.new(get_path(), "input")
			message.append_int(_input_send_buffer.size())
			for input: PlayerInput in _input_send_buffer:
				message.append_string(input.serialize())
			_input_send_buffer.clear()
			MultiplayerManager.send(message)


func _game_client_receive_state(message: MultiplayerMessage) -> void:
	if !message.matches_path(get_path()):
		return

	if message.name != "state":
		push_error(
			"Game client received unexpected message. Expected 'state'. Got '%s'." % message.name
		)
		return

	if is_local_player:
		if message.get_int(0) != 1:
			push_error(
				(
					"Game host sent too many states for game client local player. num_states=%d"
					% message.get_int(0)
				)
			)
			return

		var state: PlayerState = PlayerState.deserialize(message.get_string(1))

		# Reset to position provided by game host.
		position = state.position

		color_index = state.color_index

		# Replay local inputs that weren't taken into consideration when the game host calculated that position.
		_local_input_buffer = _local_input_buffer.filter(
			func(input: PlayerInput) -> bool: return input.message_num > state.message_num
		)
		for input: PlayerInput in _local_input_buffer:
			_apply_input(input)
		_position_changed()

	else:
		var num_states: int = message.get_int(0)
		for i: int in range(num_states):
			var state: PlayerState = PlayerState.deserialize(message.get_string(i + 1))
			_state_receive_buffer.append(state)
