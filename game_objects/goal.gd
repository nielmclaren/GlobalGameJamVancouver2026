class_name Goal
extends Area2D

signal picked_up(player: Player)

var coord: Vector2i

@onready var _debounce_timer: Timer = %DebounceTimer


func _process(_delta: float) -> void:
	if !_debounce_timer.is_stopped():
		return

	var bodies: Array[Node2D] = get_overlapping_bodies()
	for body: Node2D in bodies:
		if body is Player:
			var player: Player = body
			_debounce_timer.start()
			picked_up.emit(player)
