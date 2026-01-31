class_name AudioControls
extends Control

@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider


func _ready() -> void:
	visibility_changed.connect(_update)

	music_slider.set_value_no_signal(AudioManager.get_music_volume_linear())
	sfx_slider.set_value_no_signal(AudioManager.get_sfx_volume_linear())

	music_slider.value_changed.connect(
		func(value: float) -> void:
			AudioServer.set_bus_volume_linear(AudioManager.get_music_bus(), value)
	)

	sfx_slider.value_changed.connect(
		func(value: float) -> void:
			AudioServer.set_bus_volume_linear(AudioManager.get_sfx_bus(), value)
	)


func _update() -> void:
	music_slider.set_value_no_signal(AudioManager.get_music_volume_linear())
	sfx_slider.set_value_no_signal(AudioManager.get_sfx_volume_linear())
