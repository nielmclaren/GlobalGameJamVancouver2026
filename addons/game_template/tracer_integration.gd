class_name TracerIntegration
extends Node


static func init() -> void:
	CustomTraceSubscriber.new().init()

	if OS.has_feature("template"):
		# Don't send PostHog events when running the game from the Godot editor.
		_init_posthog_tracer()

	Tracer.trace("Here we go.")

	var scene: PackedScene = load("res://addons/game_template/tracer_integration.tscn")
	var instance: TracerIntegration = scene.instantiate()
	Engine.get_main_loop().root.add_child.call_deferred(instance)


static func quit() -> void:
	# Don't accept any more trace events because they would cause the quit to stall.
	PostHog.ignore_events(true)
	await PostHog.flush()


static func _init_posthog_tracer() -> void:
	#PostHog.send_event_successful.connect(func() -> void: print("PostHog event send success."))
	PostHog.send_event_failed.connect(func() -> void: print("PostHog event FAILED."))

	var Uuid: Resource = preload("res://addons/uuid/uuid.gd")

	var distinct_id: String

	var file_name: String = "user://tracer_integration_distinct_id.json"
	if FileAccess.file_exists(file_name):
		var file: FileAccess = FileAccess.open(file_name, FileAccess.READ)
		distinct_id = file.get_as_text()
		file.close()

	else:
		@warning_ignore("unsafe_method_access")
		distinct_id = Uuid.v4()

		var file: FileAccess = FileAccess.open(file_name, FileAccess.WRITE)
		file.store_string(distinct_id)
		file.close()

	print("PostHog distinct ID: %s" % distinct_id)

	PostHogTracerSubscriber.new().with_distinct_id(distinct_id).init()

	var os: Dictionary = {
			"locale": OS.get_locale(),
			"locale_language": OS.get_locale_language(),
			"memory_info": OS.get_memory_info(),
			"model_name": OS.get_model_name(),
			"name": OS.get_name(),
			"processor_count": OS.get_processor_count(),
			"processor_name": OS.get_processor_name(),
			"version": OS.get_version(),
			"version_alias": OS.get_version_alias(),
		}
	if os.name != "Web":
		os["unique_id"] = OS.get_unique_id()

	Tracer.trace("Operating system info.", {"os": os})


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var key_event: InputEventKey = event
		if key_event.keycode == KEY_BACKSLASH and key_event.ctrl_pressed:
			Tracer.trace("Disabling telemetry.")
			await PostHog.flush()
			PostHog.ignore_events(true)
