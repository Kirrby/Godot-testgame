# NumberPad.gd
#
# Script for the number pad UI.
# It emits signals when a number, the clear button, or the draft button is pressed.
class_name NumberPad
extends VBoxContainer

signal number_pressed(number)
signal clear_pressed
signal draft_mode_toggled(is_on)

@onready var draft_button = $ActionsContainer/Draft

func _ready() -> void:
	# Number buttons are still in GridContainer, so this part is fine.
	for i in range(1, 10):
		var button = get_node("GridContainer/Num" + str(i)) as Button
		button.pressed.connect(func(): self.number_pressed.emit(i))
	
	# The Clear button is now in ActionsContainer.
	var clear_button = get_node("ActionsContainer/Clear") as Button
	clear_button.pressed.connect(self.clear_pressed.emit)
	
	draft_button.toggled.connect(self.draft_mode_toggled.emit)
	draft_button.toggled.connect(_on_draft_button_toggled)

func _on_draft_button_toggled(is_on: bool) -> void:
	if is_on:
		draft_button.self_modulate = Color(0.8, 1.0, 0.8)
	else:
		draft_button.self_modulate = Color(1.0, 1.0, 1.0)
