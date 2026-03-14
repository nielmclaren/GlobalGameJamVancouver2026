class_name PlayerInput
extends RefCounted

var direction: Vector2
var delta: float
var ticks: int = -1
var message_num: int = -1


static func filter_after(min_ticks: int) -> Callable:
	return func(input: PlayerInput) -> bool: return input.ticks > min_ticks


func serialize() -> String:
	return JSON.stringify(
		[Utils.vector2_to_string(direction, 3), "%.6f" % delta, str(ticks), str(message_num)]
	)


static func deserialize(message: String) -> PlayerInput:
	var parts: PackedStringArray = JSON.parse_string(message)
	var input: PlayerInput = PlayerInput.new()
	input.direction = Utils.string_to_vector2(parts[0])
	input.delta = float(parts[1])
	input.ticks = int(parts[2])
	input.message_num = int(parts[3])
	return input
