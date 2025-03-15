extends Button

func _ready():
	pivot_offset = custom_minimum_size / 2

func _set_text(text: String):
	$Label.text = text

func set_button_size(button_size: Vector2):
	custom_minimum_size = button_size
	$ColorRect.size = button_size

func set_selected(_selected: bool):
	pass
