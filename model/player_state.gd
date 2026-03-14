class_name PlayerState
extends RefCounted

var direction: Vector2
var position: Vector2
var ticks: int = -1
var message_num: int = -1


static func filter_after(min_ticks: int) -> Callable:
	return func(state: PlayerState) -> bool: return state.ticks > min_ticks


func serialize() -> String:
	return JSON.stringify(
		[
			Utils.vector2_to_string(direction, 3),
			Utils.vector2_to_string(position, 3),
			str(ticks),
			str(message_num)
		]
	)


static func deserialize(message: String) -> PlayerState:
	var parts: PackedStringArray = JSON.parse_string(message)
	var input: PlayerState = PlayerState.new()
	input.direction = Utils.string_to_vector2(parts[0])
	input.position = Utils.string_to_vector2(parts[1])
	input.ticks = int(parts[2])
	input.message_num = int(parts[3])
	return input
