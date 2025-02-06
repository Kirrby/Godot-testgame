extends Node2D
class_name logic
var state 
var output := false
var body
var body2
var input
var input2

var i = 0

var dragging = false
var dragging_point_index: int = -1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	i = i + delta
	if i > 0.1:
		if body != null:
			input = body.get_parent().signal_output()
			signal_input(input)
			output = !state
			i = 0
		else:
			output = false
			i = 0
	pass

func signal_input(input:bool) -> void:
	state = input
	pass

func signal_output() -> bool:
	return output


func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("end"):
		if body != null and area != body:
			body2 = area
		else:
			body = area
	pass # Replace with function body.


func _on_area_2d_area_exited(area: Area2D) -> void:
	if area == body:
		body = null
	elif area == body2:
		body2 = null
	
	pass # Replace with function body.

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#if event.is_pressed():
				## Check if mouse is near any line point
				#if global_position.distance_to(get_global_mouse_position()) < 60:
					#dragging_point_index = 1
			#else:
				#dragging_point_index = -1
	#elif event is InputEventMouseMotion and dragging_point_index != -1:
		## Update the dragged point position
		#global_position = get_global_mouse_position()
