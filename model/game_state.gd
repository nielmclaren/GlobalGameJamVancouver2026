class_name GameState
extends RefCounted

var masks: Array[MaskState] = []
var ticks: int = -1
var message_num: int = -1


static func filter_after(min_ticks: int) -> Callable:
	return func(state: GameState) -> bool: return state.ticks > min_ticks


func serialize() -> String:
	var masks_str: String = JSON.stringify(
		masks.map(func(d: MaskState) -> String: return d.serialize())
	)
	return JSON.stringify([str(ticks), str(message_num), masks_str])


static func deserialize(message: String) -> GameState:
	var parts: PackedStringArray = JSON.parse_string(message)
	var input: GameState = GameState.new()
	input.ticks = int(parts[0])
	input.message_num = int(parts[1])

	var mask_strs: Array = JSON.parse_string(parts[2])
	input.masks.assign(mask_strs.map(func(d: String) -> MaskState: return MaskState.deserialize(d)))

	return input
