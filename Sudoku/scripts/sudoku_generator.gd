# SudokuGenerator.gd
#
# A utility class for generating and solving 9x9 Sudoku puzzles.
# It uses a backtracking algorithm to ensure that every puzzle generated
# has a single, unique solution.
# This class does not inherit from Node and is intended to be used as a static helper.
class_name SudokuGenerator

const GRID_SIZE = 9
const BOX_SIZE = 3

# Difficulty levels defined by the number of cells to remove from a solved grid.
enum Difficulty {
	EASY = 40,
	MEDIUM = 50,
	HARD = 55 # Reduced from 60 for faster generation
}

# Generates a new Sudoku puzzle with a unique solution.
# Returns a Dictionary with two keys: "puzzle" and "solution".
static func generate(difficulty: Difficulty = Difficulty.MEDIUM) -> Dictionary:
	var board = _create_empty_grid()
	
	# 1. Generate a fully solved Sudoku board.
	_solve(board)
	var solution = deep_copy(board)
	
	# 2. Poke holes in the solved board to create the puzzle.
	var cells = []
	for r in GRID_SIZE:
		for c in GRID_SIZE:
			cells.append(Vector2i(r, c))
	cells.shuffle()
	
	var removed_count = 0
	for cell_pos in cells:
		if removed_count >= difficulty:
			break
			
		var r = cell_pos.x
		var c = cell_pos.y
		
		if board[r][c] == 0: continue

		var backup = board[r][c]
		board[r][c] = 0
		
		# 3. Check if the puzzle still has a unique solution.
		var temp_board = deep_copy(board)
		if _count_solutions(temp_board) != 1:
			# If not unique, restore the number and try another cell.
			board[r][c] = backup
		else:
			removed_count += 1
			
	return {
		"puzzle": board,
		"solution": solution
	}

# --- Private Helper Functions ---

# Solves a Sudoku board in-place using backtracking.
static func _solve(board: Array) -> bool:
	var empty_pos = _find_empty(board)
	if empty_pos == Vector2i(-1, -1):
		return true
		
	var r = empty_pos.x
	var c = empty_pos.y
	
	var nums = range(1, GRID_SIZE + 1)
	nums.shuffle()
	
	for num in nums:
		if _is_valid(board, r, c, num):
			board[r][c] = num
			if _solve(board):
				return true
			board[r][c] = 0
			
	return false

# Counts the number of possible solutions for a given board.
static func _count_solutions(board: Array) -> int:
	# Use an array to pass the count by reference through the recursion.
	var count_ref = [0]
	_count_solutions_recursive(board, count_ref)
	return count_ref[0]

static func _count_solutions_recursive(board: Array, count_ref: Array) -> void:
	if count_ref[0] > 1:
		return

	var empty_pos = _find_empty(board)
	if empty_pos == Vector2i(-1, -1):
		count_ref[0] += 1
		return

	var r = empty_pos.x
	var c = empty_pos.y

	for num in range(1, GRID_SIZE + 1):
		if _is_valid(board, r, c, num):
			board[r][c] = num
			_count_solutions_recursive(board, count_ref)
			board[r][c] = 0

# Finds the next empty cell (value 0), returning its position.
static func _find_empty(board: Array) -> Vector2i:
	for r in GRID_SIZE:
		for c in GRID_SIZE:
			if board[r][c] == 0:
				return Vector2i(r, c)
	return Vector2i(-1, -1)

# Checks if placing a number in a given cell is valid according to Sudoku rules.
static func _is_valid(board: Array, r: int, c: int, num: int) -> bool:
	for i in GRID_SIZE:
		if board[r][i] == num: return false
	for i in GRID_SIZE:
		if board[i][c] == num: return false
	var box_start_r = r - r % BOX_SIZE
	var box_start_c = c - c % BOX_SIZE
	for i in BOX_SIZE:
		for j in BOX_SIZE:
			if board[box_start_r + i][box_start_c + j] == num: return false
	return true

# Creates a 9x9 grid initialized with zeros.
static func _create_empty_grid() -> Array:
	var grid = []
	grid.resize(GRID_SIZE)
	for r in GRID_SIZE:
		grid[r] = []
		grid[r].resize(GRID_SIZE)
		grid[r].fill(0)
	return grid

# Helper to perform a deep copy of the board array.
static func deep_copy(arr: Array) -> Array:
	var new_arr = []
	for item in arr:
		if item is Array:
			new_arr.append(deep_copy(item))
		else:
			new_arr.append(item)
	return new_arr
