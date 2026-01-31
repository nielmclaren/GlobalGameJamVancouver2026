class_name Main
extends Node2D

@onready var title_screen: TitleScreen = %TitleScreen
@onready var credits_screen: CreditsScreen = %CreditsScreen
@onready var game_container: Node2D = %GameContainer
@onready var pause_menu: PauseMenu = %PauseMenu

var game_scene: PackedScene

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

	game_scene = load("res://game.tscn")

	process_mode = Node.PROCESS_MODE_ALWAYS
	game_container.process_mode = Node.PROCESS_MODE_PAUSABLE

	title_screen.play_pressed.connect(_play)
	title_screen.credits_pressed.connect(_show_credits)
	title_screen.exit_pressed.connect(_exit)
	title_screen.fullscreen_pressed.connect(_toggle_fullscreen)

	pause_menu.resume_pressed.connect(_toggle_pause_menu)
	pause_menu.abandon_pressed.connect(_abandon)
	pause_menu.credits_pressed.connect(_show_credits)
	pause_menu.exit_pressed.connect(_exit)
	pause_menu.fullscreen_pressed.connect(_toggle_fullscreen)
	pause_menu.hide()

	credits_screen.done_pressed.connect(_hide_credits)
	credits_screen.hide()


func _play() -> void:
	Tracer.trace("Play clicked.")
	if _game:
		_game.queue_free()
		_game = null

	title_screen.hide()
	credits_screen.hide()

	_game = game_scene.instantiate()
	game_container.add_child(_game)


func _abandon() -> void:
	Tracer.trace("Abandon clicked.")
	if _game:
		_game.queue_free()
		_game = null

	title_screen.hide()
	credits_screen.hide()

	_game = game_scene.instantiate()
	game_container.add_child(_game)


	if _game:
		_game.queue_free()
		_game = null

	title_screen.show()
	pause_menu.hide()
	credits_screen.hide()

	_is_pause_menu = false
	_prev_paused = false
	get_tree().paused = false


func _show_credits() -> void:
	Tracer.trace("Show credits clicked.")
	credits_screen.show()


func _hide_credits() -> void:
	Tracer.trace("Hide credits clicked.")
	credits_screen.hide()


func _exit() -> void:
	Tracer.trace("Exit clicked.")
	_quit()


func _quit() -> void:
	Tracer.trace("Quitting.")
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		Tracer.trace("Quit notification received.")
		await TracerIntegration.quit()
		get_tree().quit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and !event.is_echo():
		Tracer.trace("ui_cancel pressed.")
		if credits_screen.visible:
			Tracer.trace("Hiding credits.")
			credits_screen.hide()

		elif _game:
			_toggle_pause_menu()
			get_viewport().set_input_as_handled()

		else:
			_quit()

	elif event.is_action_pressed("pause") and !event.is_echo():
		if _game:
			_toggle_pause_menu()
			get_viewport().set_input_as_handled()


func _toggle_pause_menu() -> void:
	if _is_pause_menu:
		Tracer.trace("Unpausing.")
		pause_menu.hide()
		get_tree().paused = _prev_paused
		_is_pause_menu = false

	else:
		Tracer.trace("Pausing.")
		pause_menu.show()
		_prev_paused = get_tree().paused
		get_tree().paused = true
		_is_pause_menu = true


func _toggle_fullscreen() -> void:
	Tracer.trace("Toggle fullscreen clicked.")
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN:
		Tracer.trace("Going fullscreen mode.")
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		Tracer.trace("Going window mode.")
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
