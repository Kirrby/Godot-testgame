extends Line2D

var dragging = false
var dragging_point_index: int = -1
@onready var begin_point = $"../begin"
@onready var end_point = $"../end"
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	points[0] = begin_point.position
	points[1] = end_point.position
	pass

#func _input(event: InputEvent) -> void:
	## Only handle events for this specific Line2D
	#if not is_instance_valid(self):
		#return
		#
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#if event.pressed:
				## Check if mouse is near any line point
				#for i in range(points.size()):
					#if points[i].distance_to(get_global_mouse_position()) < 10:
						#dragging_point_index = i
						#break
			#else:
				#dragging_point_index = -1
				#
	#elif event is InputEventMouseMotion and dragging_point_index != -1:
		## Update the dragged point position
		#var new_points = points
		#new_points[dragging_point_index] = get_global_mouse_position() - global_position
		#points = new_points
