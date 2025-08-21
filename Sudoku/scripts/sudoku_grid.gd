# SudokuGrid.gd
#
# A custom Control node responsible for drawing the Sudoku grid, numbers, and highlights.
# It handles user input for selecting cells and communicates with the GameState.
# This approach is highly efficient as it uses drawing commands instead of many nodes.
class_name SudokuGrid
extends Control

# Emitted when a player clicks on a cell.
# pos (Vector2i): The row and column of the selected cell.
signal cell_selected(pos)

# --- THEME VARIABLES --- #
@export var background_color: Color = Color(1, 0.98, 0.96)
@export var line_color: Color = Color.GRAY
@export var thick_line_color: Color = Color.BLACK
@export var selected_cell_color: Color = Color("#FFD700") # Gold
@export var highlight_color: Color = Color("#FFEEAA") # Light Gold
@export var puzzle_font_color: Color = Color.BLACK
@export var player_font_color: Color = Color(0.1, 0.1, 0.7)
@export var draft_font_color: Color = Color.DARK_GRAY
@export var error_highlight_color: Color = Color(1.0, 0.7, 0.7, 0.7)
@export var conflict_font_color: Color = Color.RED

var _cell_size: float = 0.0
var _grid_size: float = 0.0
var _offset: Vector2 = Vector2.ZERO

var selected_cell: Vector2i = Vector2i(-1, -1)
var selected_number: int = 0
var error_cells: Array[Vector2i] = []
var conflict_cells: Array[Vector2i] = []

var _puzzle_font: Font
var _player_font: Font
var _draft_font: Font

func _ready() -> void:
	GameState.new_game_started.connect(func(): 
		selected_cell = Vector2i(-1, -1)
		selected_number = 0
		error_cells.clear()
		conflict_cells.clear()
		queue_redraw()
	)
	_setup_fonts()
	resized.connect(queue_redraw)

func _setup_fonts() -> void:
	_puzzle_font = get_theme_default_font()
	_player_font = get_theme_default_font()
	_draft_font = get_theme_default_font()

func _draw() -> void:
	_grid_size = min(size.x, size.y)
	_offset = Vector2((size.x - _grid_size) / 2.0, (size.y - _grid_size) / 2.0)
	_cell_size = _grid_size / 9.0
	if _grid_size <= 0: return

	draw_rect(Rect2(_offset, Vector2(_grid_size, _grid_size)), background_color)
	_draw_highlights()
	_draw_error_highlights()
	_draw_grid_lines()
	_draw_numbers()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _cell_size == 0: return
		var click_pos = event.position - _offset
		var r = int(click_pos.y / _cell_size)
		var c = int(click_pos.x / _cell_size)
		if r >= 0 and r < 9 and c >= 0 and c < 9:
			selected_cell = Vector2i(r, c)
			error_cells.clear()
			queue_redraw()
			cell_selected.emit(selected_cell)

func _draw_grid_lines() -> void:
	for i in range(10):
		var line_width = 2.0 if i % 3 == 0 else 1.0
		var color = thick_line_color if i % 3 == 0 else line_color
		draw_line(_offset + Vector2(i * _cell_size, 0), _offset + Vector2(i * _cell_size, _grid_size), color, line_width)
		draw_line(_offset + Vector2(0, i * _cell_size), _offset + Vector2(_grid_size, i * _cell_size), color, line_width)

func _draw_highlights() -> void:
	if selected_cell.x != -1:
		var r = selected_cell.x
		var c = selected_cell.y
		var box_start_r = r - r % 3
		var box_start_c = c - c % 3
		draw_rect(Rect2(_offset + Vector2(0, r * _cell_size), Vector2(_grid_size, _cell_size)), highlight_color)
		draw_rect(Rect2(_offset + Vector2(c * _cell_size, 0), Vector2(_cell_size, _grid_size)), highlight_color)
		draw_rect(Rect2(_offset + Vector2(box_start_c * _cell_size, box_start_r * _cell_size), Vector2(_cell_size * 3, _cell_size * 3)), highlight_color)
		draw_rect(Rect2(_offset + Vector2(c * _cell_size, r * _cell_size), Vector2(_cell_size, _cell_size)), selected_cell_color)

	if selected_number != 0:
		for r in 9:
			for c in 9:
				if GameState.player_board[r][c] == selected_number:
					draw_rect(Rect2(_offset + Vector2(c * _cell_size, r * _cell_size), Vector2(_cell_size, _cell_size)), selected_cell_color)

func _draw_numbers() -> void:
	if not _puzzle_font: return
	var puzzle_font_size = int(_cell_size * 0.7)
	var draft_font_size = int(_cell_size * 0.25)
	if puzzle_font_size <= 0: return

	for r in 9:
		for c in 9:
			var cell_center = _offset + Vector2(c * _cell_size + _cell_size * 0.5, r * _cell_size + _cell_size * 0.5)
			var num = GameState.player_board[r][c]
			if num != 0:
				var is_puzzle_num = GameState.puzzle_board[r][c] != 0
				var font = _puzzle_font if is_puzzle_num else _player_font
				var color = player_font_color
				if not is_puzzle_num and conflict_cells.has(Vector2i(r, c)):
					color = conflict_font_color
				elif is_puzzle_num:
					color = puzzle_font_color
				
				var text = str(num)
				var text_size = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, puzzle_font_size)
				var ascent = font.get_ascent(puzzle_font_size)
				var draw_pos = cell_center - Vector2(text_size.x / 2.0, text_size.y / 2.0 - ascent)
				draw_string(font, draw_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, puzzle_font_size, color)
			else:
				var drafts: Array = GameState.draft_board[r][c]
				if not drafts.is_empty():
					if draft_font_size <= 0: continue
					for i in range(3):
						for j in range(3):
							var draft_num = i * 3 + j + 1
							if drafts.has(draft_num):
								var draft_pos_in_cell = Vector2((j + 0.5) * _cell_size / 3.0, (i + 0.5) * _cell_size / 3.0)
								var draft_center = _offset + Vector2(c * _cell_size, r * _cell_size) + draft_pos_in_cell
								var text = str(draft_num)
								var text_size = _draft_font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, draft_font_size)
								var ascent = _draft_font.get_ascent(draft_font_size)
								var draw_pos = draft_center - Vector2(text_size.x / 2.0, text_size.y / 2.0 - ascent)
								draw_string(_draft_font, draw_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, draft_font_size, draft_font_color)

func _draw_error_highlights() -> void:
	for pos in error_cells:
		draw_rect(Rect2(_offset + Vector2(pos.y * _cell_size, pos.x * _cell_size), Vector2(_cell_size, _cell_size)), error_highlight_color)
