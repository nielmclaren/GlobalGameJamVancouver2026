class_name PostHogTracerSubscriber
extends Node

var filter: int = ~0
var distinct_id: String

func with_distinct_id(id: String) -> PostHogTracerSubscriber:
	distinct_id = id
	return self

func init() -> void:
	Tracer.add_child(self)
	Tracer.sent_event.connect(on_sent_event)

func on_sent_event() -> void:
	var trace_event: Tracer.Trace = Tracer.current_event
	if trace_event.level & filter == 0:
		return

	var app: String = ProjectSettings.get_setting("application/config/name")
	var version: String = ProjectSettings.get_setting("application/config/version")

	var posthog_event := PostHogEvent.new()
	posthog_event.event_name = trace_event.msg
	posthog_event.distinct_id = distinct_id
	posthog_event.properties = {
		"app": app,
		"version": version,
		"log_level": Tracer.level_string(trace_event.level),
		"is_debug_build": OS.is_debug_build(),
		"is_template": OS.has_feature("template"),
		"function_name": trace_event.function_name,
		"module_name": trace_event.module,
		"thread_id": trace_event.thread_id,
		"span_stack": _get_span_stack(trace_event),
		"ticks_msec": Time.get_ticks_msec(),
	}.merged(trace_event.fields, true) # Overwrite with custom fields.
	posthog_event.timestamp = trace_event.timestamp

	PostHog.send_event(posthog_event)


func _get_span_stack(trace_event: Tracer.Trace) -> String:
	var result: String = ""
	for span in (
		Tracer.span_stack
			.map(func(s): return s.get_ref())
			.filter(func(s): return s != null)
	):
		if span.level & filter == 0:
			continue
		if span.level > trace_event.level:
			continue
		var span_text = ""
		if !span.fields.is_empty():
			span_text += "{"
			for key in span.fields:
				var value = span.fields[key]
				span_text += key + "=" + value + ", "
			span_text = span_text.rstrip(", ") + "}"
		result = span.name + span_text + ": " + result
	return result
