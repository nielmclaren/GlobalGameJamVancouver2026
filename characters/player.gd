class_name Player
extends CharacterBody2D

# Emitted when the player reveals themselves, e.g., by attacking.
signal unmasked

# Emitted when the player goes back into hiding, e.g., after attack.
signal masked

const SPEED: float = 20000

@onready var _base: Node2D = %Base
@onready var _attack_art: Node2D = %AttackArt
@onready var _attack_area: Area2D = %AttackArea
@onready var _animation: AnimationPlayer = %AnimationPlayer

@export var player_num: int = 0

var color: Color

var _dir: Vector2


func pickup_mask(mask: Mask) -> void:
	color = mask.color
	_base.modulate = mask.color


func take_hit() -> void:
	print("Player %d got hit." % player_num)
	_animation.play("hit")


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


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("attack%d" % player_num):
		_try_attack()


func _try_attack() -> void:
	_flash_attack_art()
	var bodies: Array[Node2D] = _attack_area.get_overlapping_bodies()
	for body: Node2D in bodies:
		if body is Player and body != self:
			var player: Player = body
			player.take_hit()


func _flash_attack_art() -> void:
	_animation.play("attack")


func _unmask() -> void:
	unmasked.emit()


func _mask() -> void:
	masked.emit()
