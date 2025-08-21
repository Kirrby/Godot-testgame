# Main.gd
#
# The main script for the entire game.
# It connects all the different components (HUD, Grid, NumberPad, GameState)
# and orchestrates the game flow.
class_name Main
extends Control

@onready var hud = $MarginContainer/VBoxContainer/HUD
@onready var sudoku_grid = $MarginContainer/VBoxContainer/SudokuGrid
@onready var number_pad = $MarginContainer/VBoxContainer/NumberPad
@onready var win_label = $WinLabel

# The draft mode is now a temporary UI state, not saved between sessions.
var _is_draft_mode: bool = false

func _ready() -> void:
	# Connect UI signals to game logic	
	hud.new_game_pressed.connect(_on_new_game_pressed)
	hud.check_pressed.connect(_on_check_pressed)
	hud.hint_pressed.connect(_on_hint_pressed)
	hud.undo_pressed.connect(_on_undo_pressed)
	hud.redo_pressed.connect(_on_redo_pressed)
	
	number_pad.number_pressed.connect(_on_number_pressed)
	number_pad.clear_pressed.connect(_on_clear_pressed)
	number_pad.draft_mode_toggled.connect(_on_draft_mode_toggled)
	sudoku_grid.cell_selected.connect(_on_cell_selected)
	
	# Connect GameState signals to UI
	GameState.game_won.connect(_on_game_won)
	GameState.new_game_started.connect(func(): sudoku_grid.queue_redraw())
	GameState.game_loaded.connect(_on_game_loaded)

	# Start or load game
	if not GameState.load_game():
		_on_new_game_pressed()
	
	_update_conflicts_and_redraw()

func _on_new_game_pressed() -> void:
	win_label.hide()
	var difficulty = hud.get_selected_difficulty()
	GameState.start_new_game(difficulty)
	sudoku_grid.conflict_cells.clear()

func _on_number_pressed(number: int) -> void:
	if sudoku_grid.selected_cell.x == -1: return

	if _is_draft_mode:
		GameState.toggle_draft_value(sudoku_grid.selected_cell, number)
	else:
		GameState.set_cell_value(sudoku_grid.selected_cell, number)
		sudoku_grid.selected_number = number
	_update_conflicts_and_redraw()

func _on_clear_pressed() -> void:
	if sudoku_grid.selected_cell.x != -1:
		GameState.set_cell_value(sudoku_grid.selected_cell, 0)
		_update_conflicts_and_redraw()

func _on_draft_mode_toggled(is_on: bool) -> void:
	_is_draft_mode = is_on

func _on_cell_selected(_pos: Vector2i) -> void:
	var num_at_pos = GameState.player_board[_pos.x][_pos.y]
	sudoku_grid.selected_number = num_at_pos
	sudoku_grid.queue_redraw()

func _on_check_pressed() -> void:
	sudoku_grid.error_cells = GameState.check_errors()
	sudoku_grid.queue_redraw()

func _on_hint_pressed() -> void:
	GameState.get_hint()
	_update_conflicts_and_redraw()

func _on_undo_pressed() -> void:
	GameState.undo()
	_update_conflicts_and_redraw()

func _on_redo_pressed() -> void:
	GameState.redo()
	_update_conflicts_and_redraw()

func _update_conflicts_and_redraw() -> void:
	sudoku_grid.conflict_cells = GameState.get_all_conflicts()
	sudoku_grid.queue_redraw()

func _on_game_won(final_time_string: String) -> void:
	win_label.text = "恭喜过关！🎉\n用时: %s" % final_time_string
	win_label.show()

func _on_game_loaded(saved_state: Dictionary) -> void:
	hud.set_difficulty(saved_state["difficulty"])

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		if OS.is_userfs_persistent():
			GameState.save_game()
