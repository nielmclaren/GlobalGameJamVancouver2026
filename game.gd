class_name Game
extends Node2D

@onready var _player_container: Node2D = %PlayerContainer
@onready var _goal_container: Node2D = %GoalContainer
@onready var _mask_container: Node2D = %MaskContainer
@onready var _tilemap: TileMapLayer = %TileMapLayer

var _mask_scene: PackedScene = load("res://game_objects/mask.tscn")
var _goal_scene: PackedScene = load("res://game_objects/goal.tscn")
var _player_scene: PackedScene = load("res://characters/player.tscn")

var _players: Array[Player]
var _masks: Array[Mask]
var _goal: Goal


func _ready() -> void:
	reset()


func reset() -> void:
	for player: Player in _players:
		player.queue_free()
	_players.clear()

	if _goal:
		_goal.queue_free()
		_goal = null

	for mask: Mask in _masks:
		mask.queue_free()
	_masks.clear()

	# Build a list of tile atlas positions with an equal number of each tile.
	var tiles: Array[Vector2i]
	for i: int in range(Constants.NUM_ROWS * Constants.NUM_COLS):
		tiles.append(Vector2i(i % Constants.COLORS.size(), 0))
	tiles.shuffle()

	for c: int in range(Constants.NUM_COLS):
		for r: int in range(Constants.NUM_ROWS):
			var tile: Vector2i = tiles.pop_back()
			_tilemap.set_cell(Vector2i(c, r), 1, tile)

	_spawn_player(0, Vector2i(0, 0))
	_spawn_player(1, Vector2i(0, 3))

	_spawn_goal()

	for i: int in range(Constants.NUM_MASKS):
		_spawn_mask()


func _spawn_player(player_num: int, coord: Vector2i) -> void:
	var player: Player = _player_scene.instantiate()
	player.player_num = player_num
	player.global_position = _tilemap.map_to_local(coord)
	_player_container.add_child(player)
	_players.append(player)


func _spawn_goal() -> void:
	var coord: Vector2i = Vector2i(3, randi() % Constants.NUM_ROWS)
	var goal: Goal = _goal_scene.instantiate()
	goal.tree_exited.connect(_goal_tree_exited)
	goal.scored.connect(_goal_scored)
	goal.global_position = _tilemap.map_to_local(coord)
	_goal_container.add_child(goal)
	_goal = goal


func _goal_tree_exited() -> void:
	_goal = null


func _goal_scored(player: Player) -> void:
	print("Player %d scored!" % player.player_num)


func _spawn_mask() -> void:
	var coord: Vector2i = Vector2i(randi() % Constants.NUM_COLS, randi() % Constants.NUM_ROWS)
	var mask: Mask = _mask_scene.instantiate()
	mask.tree_exited.connect(_mask_tree_exited.bind(mask))
	mask.global_position = _tilemap.map_to_local(coord)
	_mask_container.add_child(mask)
	_masks.append(mask)


func _mask_tree_exited(mask: Mask) -> void:
	_masks.erase(mask)
	_spawn_mask()


func _is_coord_empty(coord: Vector2i) -> bool:
	for player: Player in _players:
		if _tilemap.local_to_map(player.global_position) == coord:
			return false

	for mask: Mask in _masks:
		if _tilemap.local_to_map(mask.global_position) == coord:
			return false

	if _goal and _tilemap.local_to_map(_goal.global_position) == coord:
		return false

	return true


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		reset()

	# Quickly quit if this is the root scene. Normally this scene would have Main as a parent.
	if (
		get_parent() == get_tree().root
		and event.is_action_pressed("ui_cancel")
		and !event.is_echo()
	):
		get_tree().quit()
