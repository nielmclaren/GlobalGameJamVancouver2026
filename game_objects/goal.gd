class_name Goal
extends Area2D

signal scored(player: Player)


func _process(_delta: float) -> void:
	var bodies: Array[Node2D] = get_overlapping_bodies()
	for body: Node2D in bodies:
		if body is Player:
			var player: Player = body
			scored.emit(player)
			queue_free()
