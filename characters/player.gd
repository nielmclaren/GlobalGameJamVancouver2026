class_name Player
extends CharacterBody2D

# Emitted when the player reveals themselves, e.g., by attacking.
signal unmasked

# Emitted when the player goes back into hiding, e.g., after attack.
signal masked

# Emitted when player gets hit.
signal hitted

const SPEED: float = 30000

@onready var _art: Node2D = %Art
@onready var _animated_sprite: AnimatedSprite2D = %AnimatedSprite2D
@onready var _crown_animated_sprite: AnimatedSprite2D = %CrownAnimatedSprite
@onready var _attack_area: Area2D = %AttackArea
@onready var _animation: AnimationPlayer = %AnimationPlayer
@onready var _weapon: Node2D = %Weapon

@export var player_num: int = 0
@export var is_stunned: bool = false
@export var is_stealthed: bool = false:
	get():
		return _is_stealthed
	set(v):
		if v != _is_stealthed:
			_is_stealthed = v
			if _is_stealthed:
				_animation.play("stealth")
			else:
				_animation.play("destealth")
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


func take_hit() -> void:
	print("Player %d got hit." % player_num)
	_animation.play("hit")
	hitted.emit()


func _ready() -> void:
	_attack_area.body_entered.connect(_attack_area_body_entered)


func _attack_area_body_entered(body: Node2D) -> void:
	if body is Player and body != self:
		_try_attack()


func _process(delta: float) -> void:
	if !is_stunned:
		_dir = _get_input_vector()
		if !_dir.is_zero_approx():
			velocity = _dir * SPEED * delta
			move_and_slide()

			is_stealthed = _game.is_in_stealth_tile(self)

	if !_dir.is_zero_approx():
		_weapon.global_rotation = _dir.angle()

		if _dir.x < 0:
			_art.scale.x = -1
		elif _dir.x > 0:
			_art.scale.x = 1

	var player_form: String = "base"
	if color_index >= 0:
		player_form = Constants.PLAYER_FORMS[color_index]
	var target_animation: String = "%s_walk" % player_form
	if _dir.is_zero_approx():
		target_animation = "%s_idle" % player_form

	if _animated_sprite.animation != target_animation:
		_animated_sprite.play(target_animation)

		if _dir.is_zero_approx():
			_crown_animated_sprite.play("default")
		else:
			_crown_animated_sprite.play("walk")


func _get_input_vector() -> Vector2:
	return Input.get_vector(
		"move_left%d" % player_num,
		"move_right%d" % player_num,
		"move_up%d" % player_num,
		"move_down%d" % player_num
	)


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


func _activate_stealth_mode() -> void:
	_set_stealth_mode(true)


func _deactivate_stealth_mode() -> void:
	_set_stealth_mode(false)


func _set_stealth_mode(v: bool) -> void:
	set_collision_layer_value(Constants.COLLISION_LAYER, !v)
	set_collision_mask_value(Constants.COLLISION_LAYER, !v)
	set_collision_layer_value(Constants.ATTACK_LAYER, !v)
	set_collision_mask_value(Constants.ATTACK_LAYER, !v)
	_attack_area.monitoring = !v
	_attack_area.monitorable = !v
