class_name PlayerInput
extends RefCounted

@export var direction: Vector2
@export var delta: float
@export var ticks: int = -1
@export var message_num: int = -1
@export var is_doomed: bool = false


static func not_doomed(input: PlayerInput) -> bool:
	return !input.is_doomed


static func filter_after(max_ticks: int) -> Callable:
	return func(input: PlayerInput) -> bool: return input.ticks >= max_ticks


func serialize() -> String:
	return _vector2_to_string(direction) + "|%.6f|%d|%d" % [delta, ticks, message_num]


static func deserialize(message: String) -> PlayerInput:
	var parts: PackedStringArray = message.split("|")
	var input: PlayerInput = PlayerInput.new()
	input.direction = _string_to_vector2(parts[0])
	input.delta = float(parts[1])
	input.ticks = int(parts[2])
	input.message_num = int(parts[3])
	return input


static func _string_to_vector2(value: String) -> Vector2:
	var parts: PackedStringArray = value.substr(1, value.length() - 2).split(", ")
	return Vector2(float(parts[0]), float(parts[1]))


func _vector2_to_string(value: Vector2) -> String:
	return "(%.3f, %.3f)" % [value.x, value.y]
