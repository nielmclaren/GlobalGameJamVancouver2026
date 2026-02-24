extends LineEdit


func _ready() -> void:
	text_changed.connect(_to_upper)


func _to_upper(new_text: String) -> void:
	var prev_caret_column: int = caret_column
	text = new_text.to_upper()
	caret_column = prev_caret_column
