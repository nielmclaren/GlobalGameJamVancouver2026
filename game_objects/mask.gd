class_name Mask
extends Area2D

signal picked_up(player: Player)

@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite2D

var color_index: int


func _ready() -> void:
	_animated_sprite.play(Constants.PLAYER_FORMS[color_index])


func _process(_delta: float) -> void:
	var bodies: Array[Node2D] = get_overlapping_bodies()
	for body: Node2D in bodies:
		if body is Player:
			var player: Player = body
			player.pickup_mask(self)
			picked_up.emit(player)
			queue_free()
