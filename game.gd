class_name Game
extends Node2D

@onready var _tilemap: TileMapLayer = %TileMapLayer


func _ready() -> void:
	reset()


func reset() -> void:
	# Build a list of tile atlas positions with an equal number of each tile.
	var tiles: Array[Vector2i]
	for i: int in range(Constants.NUM_ROWS * Constants.NUM_COLS):
		tiles.append(Vector2i(i % Constants.COLORS.size(), 0))
	tiles.shuffle()

	for c: int in range(4):
		for r: int in range(4):
			var tile: Vector2i = tiles.pop_back()
			_tilemap.set_cell(Vector2i(c, r), 1, tile)


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
