class_name AudioManager
extends Node2D


static func get_music_bus() -> int:
	return AudioServer.get_bus_index("Music")


static func get_music_volume_linear() -> float:
	return AudioServer.get_bus_volume_linear(get_music_bus())


static func set_music_volume_linear(value: float) -> void:
	AudioServer.set_bus_volume_linear(get_music_bus(), value)


static func get_sfx_bus() -> int:
	return AudioServer.get_bus_index("Sfx")


static func get_sfx_volume_linear() -> float:
	return AudioServer.get_bus_volume_linear(get_sfx_bus())


static func set_sfx_volume_linear(value: float) -> void:
	AudioServer.set_bus_volume_linear(get_sfx_bus(), value)
