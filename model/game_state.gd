class_name GameState
extends RefCounted

var masks: Array[MaskState] = []
var goal_coord: Vector2i = Vector2i(-1, -1)
var scores: Array[int] = [0, 0]
var ticks: int = -1
var message_num: int = -1


func has_goal() -> bool:
	return goal_coord.x >= 0


static func filter_after(min_ticks: int) -> Callable:
	return func(state: GameState) -> bool: return state.ticks > min_ticks


func serialize() -> String:
	var masks_str: String = JSON.stringify(
		masks.map(func(d: MaskState) -> String: return d.serialize())
	)
	var scores_str: String = JSON.stringify(scores)
	return JSON.stringify(
		[str(ticks), str(message_num), masks_str, Utils.vector2i_to_string(goal_coord), scores_str]
	)


static func deserialize(message: String) -> GameState:
	var parts: PackedStringArray = JSON.parse_string(message)
	var input: GameState = GameState.new()
	input.ticks = int(parts[0])
	input.message_num = int(parts[1])

	var mask_strs: Array = JSON.parse_string(parts[2])
	input.masks.assign(mask_strs.map(func(d: String) -> MaskState: return MaskState.deserialize(d)))

	input.goal_coord = Utils.string_to_vector2i(parts[3])

	var parsed_scores: Array = JSON.parse_string(parts[4])
	input.scores.assign(parsed_scores)
	return input
