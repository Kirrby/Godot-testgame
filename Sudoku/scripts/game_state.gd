# GameState.gd
extends Node

signal game_won(final_time_string)
signal timer_updated(time_string)
signal new_game_started
# Emitted after a game is successfully loaded, carrying the UI state.
signal game_loaded(saved_ui_state)

const SAVE_FILE_PATH = "user://sudoku_save.json"

var puzzle_board: Array = []
var player_board: Array = []
var solution_board: Array = []
var draft_board: Array = []

# --- STATE TO PERSIST --- #
var current_difficulty: SudokuGenerator.Difficulty = SudokuGenerator.Difficulty.MEDIUM
var is_draft_mode_active: bool = false
# ------------------------ #

var _undo_stack: Array = []
var _redo_stack: Array = []
var _timer: Timer
var _time_elapsed: int = 0
var _is_game_active: bool = false

func _ready() -> void:
	_timer = Timer.new()
	_timer.wait_time = 1.0
	_timer.timeout.connect(_on_timer_timeout)
	add_child(_timer)
	puzzle_board = SudokuGenerator._create_empty_grid()
	player_board = SudokuGenerator.deep_copy(puzzle_board)
	solution_board = SudokuGenerator.deep_copy(puzzle_board)
	draft_board = SudokuGenerator._create_empty_grid()
	for r in 9:
		for c in 9:
			draft_board[r][c] = []

func start_new_game(difficulty: SudokuGenerator.Difficulty) -> void:
	current_difficulty = difficulty # Remember the difficulty
	var data = SudokuGenerator.generate(difficulty)
	puzzle_board = data["puzzle"]
	solution_board = data["solution"]
	player_board = SudokuGenerator.deep_copy(puzzle_board)
	for r in 9:
		for c in 9:
			draft_board[r][c] = []
	_undo_stack.clear()
	_redo_stack.clear()
	_time_elapsed = 0
	_timer.start()
	_is_game_active = true
	new_game_started.emit()

func set_cell_value(pos: Vector2i, value: int) -> void:
	if not _is_game_active or puzzle_board[pos.x][pos.y] != 0: return
	var old_value = player_board[pos.x][pos.y]
	if old_value == value: return
	player_board[pos.x][pos.y] = value
	_add_undo_action({"pos": pos, "old": old_value, "new": value})
	_check_for_win()

func toggle_draft_value(pos: Vector2i, value: int) -> void:
	if not _is_game_active or puzzle_board[pos.x][pos.y] != 0: return
	if player_board[pos.x][pos.y] != 0: set_cell_value(pos, 0)
	var drafts: Array = draft_board[pos.x][pos.y]
	var index = drafts.find(value)
	if index == -1:
		drafts.append(value)
		drafts.sort()
	else:
		drafts.remove_at(index)

func undo() -> void:
	if _undo_stack.is_empty(): return
	var action = _undo_stack.pop_back()
	_redo_stack.push_back(action)
	var pos = action["pos"]
	player_board[pos.x][pos.y] = action["old"]

func redo() -> void:
	if _redo_stack.is_empty(): return
	var action = _redo_stack.pop_back()
	_undo_stack.push_back(action)
	var pos = action["pos"]
	player_board[pos.x][pos.y] = action["new"]

func get_hint() -> void:
	var empty_cells = []
	for r in 9:
		for c in 9:
			if player_board[r][c] == 0: empty_cells.append(Vector2i(r, c))
	if empty_cells.is_empty(): return
	empty_cells.shuffle()
	var pos = empty_cells[0]
	var correct_value = solution_board[pos.x][pos.y]
	set_cell_value(pos, correct_value)

func check_errors() -> Array[Vector2i]:
	var errors: Array[Vector2i] = []
	for r in 9:
		for c in 9:
			if player_board[r][c] != 0 and player_board[r][c] != solution_board[r][c]:
				errors.append(Vector2i(r, c))
	return errors

func get_all_conflicts() -> Array[Vector2i]:
	var conflicts_dict: Dictionary = {}
	for i in 9:
		var row_counts = {}; var col_counts = {}
		for j in 9:
			var row_num = player_board[i][j]
			if row_num != 0: row_counts[row_num] = row_counts.get(row_num, []) + [Vector2i(i, j)]
			var col_num = player_board[j][i]
			if col_num != 0: col_counts[col_num] = col_counts.get(col_num, []) + [Vector2i(j, i)]
		for num in row_counts: 
			if row_counts[num].size() > 1: 
				for pos in row_counts[num]: conflicts_dict[pos] = true
		for num in col_counts: 
			if col_counts[num].size() > 1: 
				for pos in col_counts[num]: conflicts_dict[pos] = true
	for box_r in range(0, 9, 3):
		for box_c in range(0, 9, 3):
			var box_counts = {}
			for r in range(box_r, box_r + 3):
				for c in range(box_c, box_c + 3):
					var num = player_board[r][c]
					if num != 0: box_counts[num] = box_counts.get(num, []) + [Vector2i(r, c)]
			for num in box_counts:
				if box_counts[num].size() > 1:
					for pos in box_counts[num]: conflicts_dict[pos] = true
	var result: Array[Vector2i] = []; result.assign(conflicts_dict.keys()); return result

func save_game() -> void:
	if not _is_game_active: return
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	var data = {
		"puzzle_board": puzzle_board,
		"player_board": player_board,
		"solution_board": solution_board,
		"draft_board": draft_board,
		"time_elapsed": _time_elapsed,
		"current_difficulty": current_difficulty,
		"is_draft_mode_active": is_draft_mode_active,
	}
	file.store_string(JSON.stringify(data))

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH): return false
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	file.close()
	if data:
		var loaded_player_board = data["player_board"]
		for r in 9: 
			for c in 9: player_board[r][c] = int(loaded_player_board[r][c])
		var loaded_puzzle_board = data["puzzle_board"]
		for r in 9: 
			for c in 9: puzzle_board[r][c] = int(loaded_puzzle_board[r][c])
		solution_board = data["solution_board"]
		draft_board = data["draft_board"]
		_time_elapsed = int(data["time_elapsed"])
		current_difficulty = data.get("current_difficulty", SudokuGenerator.Difficulty.MEDIUM)
		is_draft_mode_active = data.get("is_draft_mode_active", false)
		_undo_stack.clear(); _redo_stack.clear(); _timer.start(); _is_game_active = true
		new_game_started.emit()
		game_loaded.emit({"difficulty": current_difficulty, "is_draft_mode": is_draft_mode_active})
		print("Game loaded.")
		return true
	return false

func _add_undo_action(action: Dictionary) -> void:
	_undo_stack.push_back(action); _redo_stack.clear()

func _get_time_string() -> String:
	var minutes = int(_time_elapsed) / 60
	var seconds = int(_time_elapsed) % 60
	return "%02d:%02d" % [minutes, seconds]

func _on_timer_timeout() -> void:
	if not _is_game_active: return
	_time_elapsed += 1
	timer_updated.emit(_get_time_string())

func _check_for_win() -> void:
	for r in 9:
		for c in 9:
			if player_board[r][c] == 0 or player_board[r][c] != solution_board[r][c]: return
	_is_game_active = false; _timer.stop(); game_won.emit(_get_time_string())
