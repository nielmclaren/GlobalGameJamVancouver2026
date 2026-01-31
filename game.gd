class_name Game
extends Node2D

@onready var _tilemap: TileMapLayer = %TileMapLayer


func _ready() -> void:
	for c: int in range(4):
		for r: int in range(4):
			_tilemap.set_cell(Vector2i(c, r), 1, Vector2i(randi() % 4, 0))


func _input(event: InputEvent) -> void:
	# Quickly quit if this is the root scene. Normally this scene would have Main as a parent.
	if (
		get_parent() == get_tree().root
		and event.is_action_pressed("ui_cancel")
		and !event.is_echo()
	):
		get_tree().quit()
