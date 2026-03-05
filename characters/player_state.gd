class_name PlayerState
extends RefCounted

@export var position: Vector2
@export var ticks: int = -1
@export var message_num: int = -1


static func filter_after(min_ticks: int) -> Callable:
	return func(state: PlayerState) -> bool: return state.ticks > min_ticks


func serialize() -> String:
	return _vector2_to_string(position) + "|%d|%d" % [ticks, message_num]


static func deserialize(message: String) -> PlayerState:
	var parts: PackedStringArray = message.split("|")
	var input: PlayerState = PlayerState.new()
	input.position = _string_to_vector2(parts[0])
	input.ticks = int(parts[1])
	input.message_num = int(parts[2])
	return input


static func _string_to_vector2(value: String) -> Vector2:
	var parts: PackedStringArray = value.substr(1, value.length() - 2).split(", ")
	return Vector2(float(parts[0]), float(parts[1]))


func _vector2_to_string(value: Vector2) -> String:
	return "(%.3f, %.3f)" % [value.x, value.y]
