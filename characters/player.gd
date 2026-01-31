class_name Player
extends CharacterBody2D

const SPEED: float = 20000

@onready var _base: Node2D = %Base

@export var player_num: int = 0

var color: Color

var _dir: Vector2


func pickup_mask(mask: Mask) -> void:
	color = mask.color
	_base.modulate = mask.color


func _process(delta: float) -> void:
	_dir = _get_input_vector()
	velocity = _dir * SPEED * delta
	move_and_slide()

	if !_dir.is_zero_approx():
		global_rotation = _dir.angle()


func _get_input_vector() -> Vector2:
	return Input.get_vector(
		"move_left%d" % player_num,
		"move_right%d" % player_num,
		"move_up%d" % player_num,
		"move_down%d" % player_num
	)
