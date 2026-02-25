class_name Main
extends Node2D

@onready var screen_container: Node2D = %ScreenContainer
@onready var credits_screen: CreditsScreen = %CreditsScreen
@onready var game_container: Node2D = %GameContainer
@onready var pause_menu: PauseMenu = %PauseMenu
@onready var title_music: AudioStreamPlayer = %TitleMusic
@onready var gameplay_music: AudioStreamPlayer = %GameplayMusic
@onready var pause_sound: AudioStreamPlayer = %PauseSound

var game_scene: PackedScene = preload("res://game.tscn")
var title_screen_scene: PackedScene = preload("res://ui/title_screen.tscn")
var local_online_scene: PackedScene = preload("res://ui/local_online_screen.tscn")
var host_join_scene: PackedScene = preload("res://ui/host_join_screen.tscn")
var character_selection_scene: PackedScene = preload("res://ui/character_selection_screen.tscn")
var winner_scene: PackedScene = preload("res://ui/winner_screen.tscn")

var _sm: CallableStateMachineNoProcess

var _is_online_multiplayer: bool = false
var _is_game_host: bool = false
var _local_player_index: int = -1

var _winner_player_index: int = -1
var _winner_color_index: int = -1
var _loser_color_index: int = -1

var _title_screen: TitleScreen
var _local_online_screen: LocalOnlineScreen
var _host_join_screen: HostJoinScreen
var _character_selection_screen: CharacterSelectionScreen
var _winner_screen: WinnerScreen

var _game: Game

# Track pause separately since Game may pause the scene tree.
var _is_pause_menu: bool = false

# Used to return the scene tree to the paused value set by Game.
var _prev_paused: bool = false


func _init() -> void:
	AudioManager.set_music_volume_linear(0.5)
	AudioManager.set_sfx_volume_linear(0.5)


func _ready() -> void:
	TracerIntegration.init()
	get_tree().set_auto_accept_quit(false)

	MultiplayerManager.message_received.connect(_message_received)
	MultiplayerManager.partner_left.connect(_partner_left)
	MultiplayerManager.disconnected.connect(_disconnected)

	_sm = CallableStateMachineNoProcess.new()
	_sm.add_state(_title_state_enter, _title_state_leave)
	_sm.add_state(_credits_state_enter, _credits_state_leave)
	_sm.add_state(_local_online_state_enter, _local_online_state_leave)
	_sm.add_state(_host_join_state_enter, _host_join_state_leave)
	_sm.add_state(_character_selection_state_enter, _character_selection_state_leave)
	_sm.add_state(_game_state_enter, _game_state_leave)
	_sm.add_state(_winner_state_enter, _winner_state_leave)
	_sm.set_initial_state(_title_state_enter)

	process_mode = Node.PROCESS_MODE_ALWAYS
	game_container.process_mode = Node.PROCESS_MODE_PAUSABLE

	pause_menu.resume_pressed.connect(_toggle_pause_menu)
	pause_menu.abandon_pressed.connect(_abandon_pressed)
	pause_menu.credits_pressed.connect(_show_credits_pressed)
	pause_menu.exit_pressed.connect(_exit_pressed)
	pause_menu.fullscreen_pressed.connect(_toggle_fullscreen)
	pause_menu.hide()

	credits_screen.done_pressed.connect(_hide_credits)
	credits_screen.hide()

	#_dev()


func _dev() -> void:
	await MultiplayerManager.connected

	_is_online_multiplayer = true
	_is_game_host = Array(OS.get_cmdline_args()).find("--server") >= 0
	if _is_game_host:
		MultiplayerManager.create_room()
		_local_player_index = 0
	else:
		MultiplayerManager.join_room("FCGDA")
		_local_player_index = 1

	await MultiplayerManager.room_ready

	_sm.change_state(_game_state_enter)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Tracer.trace("Quit notification received.")
		MultiplayerManager.leave_room()
		await TracerIntegration.quit()
		get_tree().quit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and !event.is_echo():
		Tracer.trace("ui_cancel pressed.")
		if credits_screen.visible:
			Tracer.trace("Hiding credits.")
			_hide_credits()

		elif _game:
			_toggle_pause_menu()
			get_viewport().set_input_as_handled()

	elif event.is_action_pressed("pause") and !event.is_echo():
		if _game:
			_toggle_pause_menu()
			get_viewport().set_input_as_handled()


func _play_pressed() -> void:
	Tracer.trace("Play clicked.")
	_sm.change_state(_local_online_state_enter)


func _local_online_canceled() -> void:
	_sm.change_state(_title_state_enter)


func _local_online_completed(is_online_multiplayer: bool) -> void:
	_is_online_multiplayer = is_online_multiplayer
	if _is_online_multiplayer:
		_sm.change_state(_host_join_state_enter)
	else:
		_sm.change_state(_character_selection_state_enter)


func _host_join_canceled() -> void:
	_sm.change_state(_title_state_enter)


func _host_join_completed(is_game_host: bool) -> void:
	print("Host join completed. is_game_host=", is_game_host)
	print("Character selection.")
	_is_game_host = is_game_host
	_sm.change_state(_character_selection_state_enter)


func _partner_left() -> void:
	_sm.change_state(_title_state_enter)


func _disconnected() -> void:
	_sm.change_state(_title_state_enter)


func _character_selection_canceled() -> void:
	_sm.change_state(_title_state_enter)


func _character_selection_completed(local_player_index: int) -> void:
	_local_player_index = local_player_index
	_sm.change_state(_game_state_enter)


func _game_started() -> void:
	title_music.stop()
	if !gameplay_music.playing:
		gameplay_music.play()
		pause_sound.play()


func _game_completed(
	winner_player_index: int, winner_color_index: int, loser_color_index: int
) -> void:
	_winner_player_index = winner_player_index
	_winner_color_index = winner_color_index
	_loser_color_index = loser_color_index

	_sm.change_state(_winner_state_enter)

	gameplay_music.stop()
	if !title_music.playing:
		title_music.play()


func _winner_completed() -> void:
	_sm.change_state(_game_state_enter)


func _abandon_pressed() -> void:
	Tracer.trace("Abandon clicked.")
	MultiplayerManager.leave_room()
	_sm.change_state(_title_state_enter)

	gameplay_music.stop()
	if !title_music.playing:
		title_music.play()


func _show_credits_pressed() -> void:
	Tracer.trace("Show credits clicked.")
	if _is_pause_menu:
		# No state change for pause menu.
		credits_screen.show()
	else:
		_sm.change_state(_credits_state_enter)


func _credits_done_pressed() -> void:
	Tracer.trace("Hide credits clicked.")
	_hide_credits()


func _hide_credits() -> void:
	if _is_pause_menu:
		# No state change for pause menu.
		credits_screen.hide()
	else:
		_sm.change_state(_title_state_enter)


func _exit_pressed() -> void:
	Tracer.trace("Exit clicked.")
	_quit()


func _quit() -> void:
	Tracer.trace("Quitting.")
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _toggle_pause_menu() -> void:
	if _is_pause_menu:
		_unpause()
		MultiplayerManager.send(MultiplayerMessage.new(get_path(), "unpause"))

	else:
		_pause()
		MultiplayerManager.send(MultiplayerMessage.new(get_path(), "pause"))


func _pause() -> void:
	Tracer.trace("Pausing.")
	pause_menu.show()
	_prev_paused = get_tree().paused
	get_tree().paused = true
	_is_pause_menu = true

	gameplay_music.stop()
	if !title_music.playing:
		title_music.play()


func _unpause() -> void:
	Tracer.trace("Unpausing.")
	pause_menu.hide()
	get_tree().paused = _prev_paused
	_is_pause_menu = false

	if _sm.get_state() == _game_state_enter:
		title_music.stop()
	# else Leave title music playing.

	if !gameplay_music.playing:
		gameplay_music.play()
		pause_sound.play()


func _toggle_fullscreen() -> void:
	Tracer.trace("Toggle fullscreen clicked.")
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		Tracer.trace("Going fullscreen mode.")
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		Tracer.trace("Going window mode.")
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _message_received(message: MultiplayerMessage) -> void:
	if !message.matches_path(get_path()):
		return

	match message.name:
		"pause":
			_pause()
		"unpause":
			_unpause()


### States


func _title_state_enter() -> void:
	_title_screen = title_screen_scene.instantiate()
	_title_screen.play_pressed.connect(_play_pressed)
	_title_screen.credits_pressed.connect(_show_credits_pressed)
	_title_screen.exit_pressed.connect(_exit_pressed)
	screen_container.add_child(_title_screen)

	# TODO: Reassess whether these are needed.
	_is_pause_menu = false
	_prev_paused = false
	get_tree().paused = false


func _title_state_leave() -> void:
	_title_screen.queue_free()


func _credits_state_enter() -> void:
	credits_screen.show()


func _credits_state_leave() -> void:
	credits_screen.hide()


func _local_online_state_enter() -> void:
	_local_online_screen = local_online_scene.instantiate()
	_local_online_screen.canceled.connect(_local_online_canceled)
	_local_online_screen.completed.connect(_local_online_completed)
	screen_container.add_child(_local_online_screen)


func _local_online_state_leave() -> void:
	_local_online_screen.queue_free()


func _host_join_state_enter() -> void:
	_host_join_screen = host_join_scene.instantiate()
	_host_join_screen.canceled.connect(_host_join_canceled)
	_host_join_screen.completed.connect(_host_join_completed)
	screen_container.add_child(_host_join_screen)


func _host_join_state_leave() -> void:
	_host_join_screen.queue_free()


func _character_selection_state_enter() -> void:
	_character_selection_screen = character_selection_scene.instantiate()
	_character_selection_screen.canceled.connect(_character_selection_canceled)
	_character_selection_screen.completed.connect(_character_selection_completed)
	_character_selection_screen.is_game_host = _is_game_host
	_character_selection_screen.is_online_multiplayer = _is_online_multiplayer
	screen_container.add_child(_character_selection_screen)


func _character_selection_state_leave() -> void:
	_character_selection_screen.queue_free()


func _game_state_enter() -> void:
	_game = game_scene.instantiate()
	_game.completed.connect(_game_completed)
	_game.is_game_host = _is_game_host
	_game.is_online_multiplayer = _is_online_multiplayer
	_game.local_player_index = _local_player_index
	game_container.add_child(_game)

	title_music.stop()


func _game_state_leave() -> void:
	_game.queue_free()
	_game = null

	pause_menu.hide()

	_is_pause_menu = false
	_prev_paused = false
	get_tree().paused = false


func _winner_state_enter() -> void:
	_winner_screen = winner_scene.instantiate()
	_winner_screen.completed.connect(_winner_completed)
	_winner_screen.winner_player_index = _winner_player_index
	_winner_screen.winner_color_index = _winner_color_index
	_winner_screen.loser_color_index = _loser_color_index
	screen_container.add_child(_winner_screen)


func _winner_state_leave() -> void:
	_winner_screen.queue_free()
