@tool

extends Node2D


func get_descendants_by_type(root: Node, type: Variant) -> Array[Node]:
	var result: Array[Node]
	var frontier: Array[Node] = root.get_children()
	while !frontier.is_empty():
		var child: Node = frontier.pop_back()
		if is_instance_of(child, type):
			result.append(child)

		else:
			frontier.append_array(child.get_children())

	return result


func get_ancestor_by_type(node: Node, type: Variant) -> Node:
	var frontier: Node = node.get_parent()
	while frontier and !is_instance_of(frontier, type):
		frontier = frontier.get_parent()
	return frontier


func lerpf(v: float, in_low: float, in_high: float, out_low: float, out_high: float) -> float:
	return out_low + (v - in_low) * (out_high - out_low) / (in_high - in_low)


func color_index_to_atlas_coord(index: int) -> Vector2i:
	return Vector2i(index, 0)


func atlas_coord_to_color_index(coord: Vector2i) -> int:
	return coord.x


func string_to_vector2(value: String) -> Vector2:
	var parts: PackedStringArray = value.substr(1, value.length() - 2).split(", ")
	return Vector2(float(parts[0]), float(parts[1]))


func string_to_vector2i(value: String) -> Vector2i:
	var parts: PackedStringArray = value.substr(1, value.length() - 2).split(", ")
	return Vector2i(parts[0].to_int(), parts[1].to_int())


func vector2_to_string(value: Vector2, decimals: int = -1) -> String:
	if decimals < 0:
		return "(%f, %f)" % [value.x, value.y]
	if decimals == 0:
		return "(%d, %d)" % [value.x, value.y]
	return ("(%." + str(decimals) + "f, %." + str(decimals) + "f)") % [value.x, value.y]


func vector2i_to_string(value: Vector2i) -> String:
	return str(value)
