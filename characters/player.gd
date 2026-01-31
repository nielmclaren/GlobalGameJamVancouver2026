class_name Player
extends CharacterBody2D

@onready var _base: Node2D = %Base

const SPEED: float = 20000

@export var player_num: int = 0


func pickup_mask(mask: Mask) -> void:
	_base.modulate = mask.color


func _process(delta: float) -> void:
	var dir: Vector2 = _get_input_vector()
	velocity = dir * SPEED * delta
	move_and_slide()


func _get_input_vector() -> Vector2:
	return Input.get_vector(
		"move_left%d" % player_num,
		"move_right%d" % player_num,
		"move_up%d" % player_num,
		"move_down%d" % player_num
	)
