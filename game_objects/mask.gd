class_name Mask
extends Area2D

var COLORS: Array[Color] = [
	Color.from_string("#6ab2e4", Color.RED),
	Color.from_string("#ca6ae4", Color.RED),
	Color.from_string("#6ae4a7", Color.RED),
	Color.from_string("#e4bf6a", Color.RED)
]

@onready var _base: Node2D = %Base

var color: Color


func _ready() -> void:
	color = COLORS[randi() % COLORS.size()]
	_base.modulate = color


func _process(_delta: float) -> void:
	var bodies: Array[Node2D] = get_overlapping_bodies()
	for body: Node2D in bodies:
		if body is Player:
			var player: Player = body
			player.pickup_mask(self)
			queue_free()
