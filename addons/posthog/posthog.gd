@tool
extends EditorPlugin

const PROJECT_SETTING_NAME := "posthog_api_key"
const ENDPOINT_SETTING_NAME := "posthog_endpoint"

func _enter_tree():
	add_autoload_singleton("PostHog", "res://addons/posthog/plugin.gd")
	add_custom_project_setting(PROJECT_SETTING_NAME, "", TYPE_STRING, PROPERTY_HINT_PASSWORD, "Your PostHog API Key (keep it private!)")
	add_custom_project_setting(ENDPOINT_SETTING_NAME, "https://", TYPE_STRING, PROPERTY_HINT_NONE, "Your PostHog API endpoint")


func _exit_tree():
	remove_autoload_singleton("PostHog")
	
	if ProjectSettings.has_setting(PROJECT_SETTING_NAME):
		ProjectSettings.set_setting(PROJECT_SETTING_NAME, null)
	if ProjectSettings.has_setting(ENDPOINT_SETTING_NAME):
		ProjectSettings.set_setting(ENDPOINT_SETTING_NAME, null)


func add_custom_project_setting(name: String, default_value, type: int, hint: int = PROPERTY_HINT_NONE, hint_string: String = "") -> void:
	if ProjectSettings.has_setting(name) or ProjectSettings.has_setting("global/" + name): return

	var setting_info: Dictionary = {
		"name": name,
		"type": type,
		"hint": hint,
		"hint_string": hint_string
	}

	ProjectSettings.set_setting(name, default_value)
	ProjectSettings.add_property_info(setting_info)
	ProjectSettings.set_initial_value(name, default_value)
	ProjectSettings.save()
