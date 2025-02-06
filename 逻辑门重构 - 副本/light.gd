extends PointLight2D
var output : bool = false
var input : bool = false
var state : bool = false
var old_state : bool = false
var body = null
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if body != null:
		enabled = body.get_parent().signal_output()
	pass

func signal_input(input:bool) -> void:
	state = input
	return

func signal_output() -> bool:
	output = state
	return output


func _on_area_2d_area_entered(area: Area2D) -> void:
	body = area
	enabled = area.get_parent().signal_output()
	print("灯泡调试",area.get_parent().signal_output())
	pass # Replace with function body.


func _on_area_2d_area_exited(area: Area2D) -> void:
	body = null
	enabled = false
	pass # Replace with function body.
