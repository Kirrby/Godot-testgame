extends Node2D
var output : bool = false
var input : bool = false
var state : bool = false
var old_state : bool = false
var body = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if state:
		$Line2D.default_color = "white"
	else:
		$Line2D.default_color = "black"

	if body != null:
		input = body.get_parent().signal_output()
		signal_input(input)
	pass


func signal_input(input:bool) -> void:
	state = input
	return

func signal_output() -> bool:
	output = state
	return output


func _on_begin_area_entered(area: Area2D) -> void:
	body = area
	input = body.get_parent().signal_output()
	print("导线调试",input)
	signal_input(input)
	pass


func _on_begin_area_exited(area: Area2D) -> void:
	state = false
	body = null
	pass
