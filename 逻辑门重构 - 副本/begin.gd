extends Area2D

var dragging = false
var dragging_point_index: int = -1
var line :Line2D
var i = 0

func _ready() -> void:
	line = $"../Line2D"

func _process(delta):
	#position = line.points[0]
	i = i + delta
	if i>5:
		print(get_parent().get_node("begin").global_position,get_parent().get_node("end").global_position)
		i = 0
	pass

#func _input(event: InputEvent) -> void:
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_LEFT:
			#if event.is_pressed():
				## Check if mouse is near any line point
				#if global_position.distance_to(get_global_mouse_position()) < 10:
					#dragging_point_index = 1
			#else:
				#dragging_point_index = -1
	#elif event is InputEventMouseMotion and dragging_point_index != -1:
		## Update the dragged point position
		#global_position = get_global_mouse_position()
