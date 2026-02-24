class_name CallableStateMachineNoProcess
extends Node

#
# Based on CallableStateMachine by FireBelley.
# @see https://gist.github.com/firebelley/96f2f82e3feaa2756fe647d8b9843174
#

var _state_dictionary: Dictionary = {}
var _current_state: String


func add_state(enter_state_callable: Callable, leave_state_callable: Callable) -> void:
	_state_dictionary[enter_state_callable.get_method()] = {
		"enter": enter_state_callable, "leave": leave_state_callable
	}


func set_initial_state(state_callable: Callable) -> void:
	var state_name: String = state_callable.get_method()
	if _state_dictionary.has(state_name):
		_set_state(state_name)

	else:
		push_warning("Failed to set initial state. No state with name " + state_name)


func change_state(state_enter_callable: Callable) -> void:
	var state_name: String = state_enter_callable.get_method()
	if _state_dictionary.has(state_name):
		_set_state.call_deferred(state_name)

	else:
		push_warning("Failed to change state. No state with name " + state_name)


func get_state() -> Callable:
	var enter_callable: Callable = _state_dictionary[_current_state].enter
	return enter_callable


func _set_state(state_name: String) -> void:
	if _current_state:
		var leave_callable: Callable = _state_dictionary[_current_state].leave
		if !leave_callable.is_null():
			leave_callable.call()

	_current_state = state_name
	var enter_callable: Callable = _state_dictionary[_current_state].enter
	if !enter_callable.is_null():
		enter_callable.call()
