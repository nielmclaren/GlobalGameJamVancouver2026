extends Node

signal send_event_successful
signal send_event_failed

signal _send_event_completed

var endpoint := "https://app.posthog.com/"

enum SendType { SINGLE, BATCH }

var sender: HTTPRequest

var request_queue: Array[PostHogEvent] = []

var _ignore_events: bool = false

const API_KEY_NAME := "api_key"
const EVENT_KEY := "event"
const TYPE_KEY := "type"
const TIMESTAMP_KEY := "timestamp"
const DISTINCT_ID_KEY := "distinct_id"
const PROPERTIES_KEY := "properties"
const BATCH_KEY := "batch"

var SINGLE_EVENT_BODY = {
	API_KEY_NAME: "", EVENT_KEY: "", PROPERTIES_KEY: {DISTINCT_ID_KEY: ""}, TIMESTAMP_KEY: null
}

var BATCH_EVENT_BODY = {API_KEY_NAME: "", BATCH_KEY: []}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	sender = HTTPRequest.new()
	add_child(sender)
	sender.request_completed.connect(_on_send_event_request_complete)

	if ProjectSettings.has_setting("global/posthog_api_key"):
		var api_key: String = ProjectSettings.get_setting("global/posthog_api_key")
		SINGLE_EVENT_BODY[API_KEY_NAME] = api_key
		BATCH_EVENT_BODY[API_KEY_NAME] = api_key

	if ProjectSettings.has_setting("global/posthog_endpoint"):
		endpoint = ProjectSettings.get_setting("global/posthog_endpoint")


func ignore_events(v: bool = true) -> void:
	_ignore_events = v


func flush() -> void:
	while (
		!request_queue.is_empty()
		or sender.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED
	):
		await _send_event_completed


func send_event(event: PostHogEvent) -> void:
	if _ignore_events:
		return

	if sender.get_http_client_status() == HTTPClient.STATUS_DISCONNECTED:
		_send_event(event)
	else:
		request_queue.push_back(event)


func _send_event(event: PostHogEvent) -> void:
	var json := JSON.new()
	var dupe := JSON.stringify(get_formatted_single_event(event))

	sender.request("%s/capture/" % endpoint, PackedStringArray(), HTTPClient.METHOD_POST, dupe)


func _send_event_batch(batched_events: Array[PostHogEvent]) -> void:
	var dupe := BATCH_EVENT_BODY.duplicate(true)
	for event in batched_events:
		var formatted_event = get_formatted_batch_event(event)
		dupe.batch.push_back(formatted_event)

	var json := JSON.new()
	var to_push = JSON.stringify(dupe)

	sender.request("%s/batch/" % endpoint, PackedStringArray(), HTTPClient.METHOD_POST, to_push)


func get_formatted_single_event(event: PostHogEvent) -> Dictionary:
	var dupe = SINGLE_EVENT_BODY.duplicate(true)
	dupe.event = event.event_name
	dupe.properties = event.properties
	dupe.properties[DISTINCT_ID_KEY] = event.distinct_id

	if !event.timestamp:
		dupe.erase(TIMESTAMP_KEY)

	return dupe


func get_formatted_batch_event(event: PostHogEvent) -> Dictionary:
	var result = get_formatted_single_event(event)
	result.erase(API_KEY_NAME)
	return result


func _on_send_event_request_complete(
	result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray
):
	if response_code == HTTPClient.RESPONSE_OK:
		send_event_successful.emit()
	else:
		push_error(
			(
				"PostHog send event failed.\nresponse_code=%s, body=%s"
				% [response_code, body.get_string_from_utf8()]
			)
		)
		send_event_failed.emit()

	if request_queue.size() > 1:
		_send_event_batch(request_queue)
	elif request_queue.size() > 0:
		_send_event(request_queue[0])
	request_queue.clear()

	_send_event_completed.emit()
