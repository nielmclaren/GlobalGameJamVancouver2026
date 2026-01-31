class_name Mask
extends Area2D

@onready var _base: Node2D = %Base

var color: Color


func _ready() -> void:
	color = Constants.COLORS[randi() % Constants.COLORS.size()]
	_base.modulate = color


func _process(_delta: float) -> void:
	var bodies: Array[Node2D] = get_overlapping_bodies()
	for body: Node2D in bodies:
		if body is Player:
			var player: Player = body
			player.pickup_mask(self)
			queue_free()
