extends Node

signal sent_event

enum Level {
	Error = 1,
	Warn = 2,
	Info = 4,
	Debug = 8,
	Trace = 16,
}

var span_stack := []

class Span:
	extends RefCounted

	var level: Tracer.Level
	var name: String
	var fields: Dictionary = {}
	var parent: WeakRef = null

	func _init(parent: Span, level: Tracer.Level, name: String, fields := {}) -> void:
		self.level = level
		self.name = name
		self.fields = fields
		self.parent = weakref(parent)

	func _notification(what):
		if what == NOTIFICATION_PREDELETE:
			Tracer.span_stack.pop_front()
			#print_debug(Tracer.span_stack.map(func(s): return s.get_ref().name))

	func enter() -> Span:
		Tracer.span_stack.push_front(weakref(self))
		#print_debug(Tracer.span_stack.map(func(s): return s.get_ref().name))
		return self

	func exit() -> void:
		Tracer.span_stack.pop_front()
		#print_debug(Tracer.span_stack.map(func(s): return s.get_ref().name))

func span(level: Tracer.Level, name: String, fields := {}) -> Span:
	return Span.new(null if span_stack.is_empty() else span_stack.front().get_ref(), level, name, fields)

class Trace:
	var level: Tracer.Level
	var msg: String
	var module: String = "unknown"
	var function_name: String = "unknown"
	var timestamp: String = (
		Time.get_datetime_string_from_system()
	)
	var fields := {}
	var thread_id := 1
	var _has_mono: bool = Engine.has_singleton("GodotSharp")

	func _init(
		msg: String, level: Tracer.Level, new_thread_id := 0, fields := {}
	) -> void:
		self.msg = msg
		self.level = level
		self.fields = fields
		var st = get_stack()
		if st.size() > 2:
			module = st[2].source.trim_prefix("res://")
			function_name = st[2].function
		elif _has_mono:
			# C#-specific stack handling
			var mono_sh_script = load("res://addons/tracer/StackHandler.cs")
			var mono_stack_handler = mono_sh_script.new()
			module = mono_stack_handler.GetModulePath()
			function_name = mono_stack_handler.GetFunctionName()
		else:
			function_name = "unknown"
		thread_id = new_thread_id


var current_event: Trace = null:
	set = set_current_event


func set_current_event(event: Trace) -> void:
	current_event = event
	sent_event.emit()


func info(msg: String, fields := {}) -> void:
	current_event = Trace.new(
		msg, Tracer.Level.Info, OS.get_thread_caller_id(), fields
	)


func debug(msg: String, fields := {}) -> void:
	current_event = Trace.new(
		msg, Tracer.Level.Debug, OS.get_thread_caller_id(), fields
	)


func warn(msg: String, fields := {}) -> void:
	current_event = Trace.new(
		msg, Tracer.Level.Warn, OS.get_thread_caller_id(), fields
	)


func error(msg: String, fields := {}) -> void:
	current_event = Trace.new(
		msg, Tracer.Level.Error, OS.get_thread_caller_id()
	)

func trace(msg: String, fields := {}) -> void:
	current_event = Trace.new(msg, Tracer.Level.Trace, OS.get_thread_caller_id(), fields)


static func level_string(level: Tracer.Level) -> String:
	match level:
		Tracer.Level.Info:
			return "INFO"
		Tracer.Level.Debug:
			return "DEBUG"
		Tracer.Level.Warn:
			return "WARN"
		Tracer.Level.Error:
			return "ERROR"
		Tracer.Level.Trace:
			return "TRACE"
		_:
			return "UNKNOWN"


static func level_colored(level: Tracer.Level) -> String:
	var color = ""
	match level:
		Tracer.Level.Info:
			color = "[color=green]%s[/color]"
		Tracer.Level.Debug:
			color = "[color=blue]%s[/color]"
		Tracer.Level.Warn:
			color = "[color=yellow]%s[/color]"
		Tracer.Level.Error:
			color = "[color=red]%s[/color]"
		Tracer.Level.Trace:
			color = "[color=magenta]%s[/color]"
		_:
			color = "[color=white]%s[/color]"
	return color % level_string(level)


static func level_colored_nice(level: Tracer.Level) -> String:
	var color = ""
	match level:
		Tracer.Level.Info:
			color = "[color=greenyellow]%s[/color]"
		Tracer.Level.Debug:
			color = "[color=dodgerblue]%s[/color]"
		Tracer.Level.Warn:
			color = "[color=gold]%s[/color]"
		Tracer.Level.Error:
			color = "[color=orangered]%s[/color]"
		Tracer.Level.Trace:
			color = "[color=maroon]%s[/color]"
		_:
			color = "[color=white]%s[/color]"
	return color % level_string(level)
