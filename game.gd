class_name Game
extends Node2D

@onready var _mask_container: Node2D = %MaskContainer
@onready var _player_container: Node2D = %PlayerContainer
@onready var _tilemap: TileMapLayer = %TileMapLayer

var _mask_scene: PackedScene = load("res://game_objects/mask.tscn")
var _player_scene: PackedScene = load("res://characters/player.tscn")

var _players: Array[Player]
var _masks: Array[Mask]


func _ready() -> void:
	reset()


func reset() -> void:
	for player: Player in _players:
		player.queue_free()
	_players.clear()

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

	var player0: Player = _player_scene.instantiate()
	player0.global_position = _tilemap.map_to_local(Vector2i(0, 3))
	player0.player_num = 0
	_player_container.add_child(player0)
	_players.append(player0)

	var player1: Player = _player_scene.instantiate()
	player1.player_num = 1
	player1.global_position = _tilemap.map_to_local(Vector2i(3, 0))
	_player_container.add_child(player1)
	_players.append(player1)

	for i: int in range(Constants.NUM_MASKS):
		var coords: Vector2i = Vector2i(randi() % Constants.NUM_COLS, randi() % Constants.NUM_ROWS)
		var mask: Mask = _mask_scene.instantiate()
		_mask_container.add_child(mask)
		_masks.append(mask)
		mask.global_position = _tilemap.map_to_local(coords)


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
