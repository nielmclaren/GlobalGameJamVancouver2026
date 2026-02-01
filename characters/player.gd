class_name Player
extends CharacterBody2D

# Emitted when the player reveals themselves, e.g., by attacking.
signal unmasked

# Emitted when the player goes back into hiding, e.g., after attack.
signal masked

# Emitted when player gets hit.
signal hitted

const SPEED: float = 20000

@onready var _base: Node2D = %Base
@onready var _attack_area: Area2D = %AttackArea
@onready var _animation: AnimationPlayer = %AnimationPlayer

@export var player_num: int = 0
@export var is_stunned: bool = false
@export var is_stealthed: bool = false:
	get():
		return _is_stealthed
	set(v):
		if v != _is_stealthed:
			_is_stealthed = v
			visible = !v
			print("Stealthed %d: " % player_num, _is_stealthed)

var color_index: int = -1

var _game: Game
var _dir: Vector2
var _is_stealthed: bool = false


func setup(game: Game) -> Player:
	_game = game
	return self


func pickup_mask(mask: Mask) -> void:
	color_index = mask.color_index
	_base.modulate = Constants.COLORS[color_index]


func take_hit() -> void:
	print("Player %d got hit." % player_num)
	_animation.play("hit")
	hitted.emit()


func _ready() -> void:
	_attack_area.body_entered.connect(_attack_area_body_entered)


func _attack_area_body_entered(body: Node2D) -> void:
	if body is Player:
		_try_attack()


func _process(delta: float) -> void:
	if !is_stunned:
		_dir = _get_input_vector()
		if !_dir.is_zero_approx():
			velocity = _dir * SPEED * delta
			move_and_slide()

			is_stealthed = _game.is_in_stealth_tile(self )

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
	if !_animation.is_playing():
		_animation.play("attack")
		_perform_attack()


func _perform_attack() -> void:
	var bodies: Array[Node2D] = _attack_area.get_overlapping_bodies()
	for body: Node2D in bodies:
		if body is Player and body != self:
			var player: Player = body
			player.take_hit()


func _unmask() -> void:
	unmasked.emit()


func _mask() -> void:
	masked.emit()
