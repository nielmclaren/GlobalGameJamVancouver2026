class_name MaskState
extends RefCounted

var id: int
var coord: Vector2i
var color_index: int


func serialize() -> String:
	return JSON.stringify([str(id), Utils.vector2i_to_string(coord), str(color_index)])


static func deserialize(message: String) -> MaskState:
	var parts: PackedStringArray = JSON.parse_string(message)
	var state: MaskState = MaskState.new()
	state.id = int(parts[0])
	state.coord = Utils.string_to_vector2i(parts[1])
	state.color_index = int(parts[2])
	return state
