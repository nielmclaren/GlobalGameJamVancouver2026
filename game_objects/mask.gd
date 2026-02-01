class_name Mask
extends Area2D

signal picked_up(player: Player)

@onready var _base: Node2D = %Base

var color_index: int


func _ready() -> void:
	_base.modulate = Constants.COLORS[color_index]


func _process(_delta: float) -> void:
	var bodies: Array[Node2D] = get_overlapping_bodies()
	for body: Node2D in bodies:
		if body is Player:
			var player: Player = body
			player.pickup_mask(self)
			picked_up.emit(player)
			queue_free()
