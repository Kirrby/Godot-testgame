# hud.gd
#
# Script for the Head-Up Display.
# It provides buttons for game actions like starting a new game, checking errors, etc.
# It also displays the timer.
class_name HUD
extends HBoxContainer

signal new_game_pressed
signal check_pressed
signal hint_pressed
signal undo_pressed
signal redo_pressed

@onready var new_game_button = $NewGameButton
@onready var check_button = $CheckButton
@onready var hint_button = $HintButton
@onready var undo_button = $UndoButton
@onready var redo_button = $RedoButton
@onready var timer_label = $TimerLabel
@onready var difficulty_button = $DifficultyButton

func _ready() -> void:
	new_game_button.pressed.connect(self.new_game_pressed.emit)
	check_button.pressed.connect(self.check_pressed.emit)
	hint_button.pressed.connect(self.hint_pressed.emit)
	undo_button.pressed.connect(self.undo_pressed.emit)
	redo_button.pressed.connect(self.redo_pressed.emit)
	
	GameState.timer_updated.connect(update_timer_label)

func update_timer_label(time_string: String) -> void:
	timer_label.text = time_string

# Correctly maps the UI selection ID to the generator's difficulty enum.
func get_selected_difficulty() -> SudokuGenerator.Difficulty:
	var selected_id = difficulty_button.get_selected_id()
	match selected_id:
		0: return SudokuGenerator.Difficulty.EASY
		1: return SudokuGenerator.Difficulty.MEDIUM
		2: return SudokuGenerator.Difficulty.HARD
	return SudokuGenerator.Difficulty.MEDIUM # Default fallback

# Correctly maps the generator's difficulty enum to the UI selection ID.
func set_difficulty(difficulty: SudokuGenerator.Difficulty) -> void:
	match difficulty:
		SudokuGenerator.Difficulty.EASY:
			difficulty_button.select(0)
		SudokuGenerator.Difficulty.MEDIUM:
			difficulty_button.select(1)
		SudokuGenerator.Difficulty.HARD:
			difficulty_button.select(2)
