class_name MultiplayerMessage
extends RefCounted

var path: String
var name: String
var args: PackedStringArray = []


static func deserialize(message: String) -> MultiplayerMessage:
	var parts: PackedStringArray = message.split(":")
	var result: MultiplayerMessage = MultiplayerMessage.new(parts[0], parts[1])
	if parts.size() > 2:
		result.args = parts[2].split(";")
	return result


func serialize() -> String:
	var args_str: String = "_" if args.is_empty() else ";".join(args)
	return path + ":" + name + ":" + args_str


func _init(path_: String, name_: String) -> void:
	path = path_
	name = name_


func setup(path_: String, name_: String) -> MultiplayerMessage:
	path = path_
	name = name_
	return self


func is_addressed_to(node: Node) -> bool:
	return path == str(node.get_path())


func append_bool(value: bool) -> MultiplayerMessage:
	args.append("1" if value else "0")
	return self


func append_float(value: float) -> MultiplayerMessage:
	args.append(str(value))
	return self


func append_int(value: int) -> MultiplayerMessage:
	args.append(str(value))
	return self


func append_string(value: String) -> MultiplayerMessage:
	args.append(value)
	return self


func append_vector2(value: Vector2) -> MultiplayerMessage:
	args.append(str(value))
	return self


func append_vector2i(value: Vector2i) -> MultiplayerMessage:
	args.append(str(value))
	return self


func get_bool(index: int) -> bool:
	return args[index] == "1"


func get_float(index: int) -> float:
	return float(args[index])


func get_int(index: int) -> int:
	return int(args[index])


func get_string(index: int) -> String:
	return args[index]


func get_vector2(index: int) -> Vector2:
	return Utils.string_to_vector2(args[index])


func get_vector2i(index: int) -> Vector2i:
	return Utils.string_to_vector2i(args[index])
