class_name PlayerState
extends RefCounted

var direction: Vector2
var position: Vector2
var color_index: int
var ticks: int = -1
var message_num: int = -1


static func filter_after(min_ticks: int) -> Callable:
	return func(state: PlayerState) -> bool: return state.ticks > min_ticks


func serialize() -> String:
	return JSON.stringify(
		[
			Utils.vector2_to_string(direction, 3),
			Utils.vector2_to_string(position, 3),
			str(color_index),
			str(ticks),
			str(message_num)
		]
	)


static func deserialize(message: String) -> PlayerState:
	var parts: PackedStringArray = JSON.parse_string(message)
	var state: PlayerState = PlayerState.new()
	state.direction = Utils.string_to_vector2(parts[0])
	state.position = Utils.string_to_vector2(parts[1])
	state.color_index = int(parts[2])
	state.ticks = int(parts[3])
	state.message_num = int(parts[4])
	return state
