class_name AutoIncrement
extends RefCounted

var _value: int = -1


func value() -> int:
	_value += 1
	return _value
