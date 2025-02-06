extends Node2D
var button_scene = load("res://check_button.tscn")
var button_start_position = Vector2(100,100)
var line_scene = load("res://line.tscn")
var line_start_position = Vector2(150,85)
var line_pos : Array = [Vector2(955.3171, 446.1005),Vector2(1024.0, 319.7574),
Vector2(448.0001, 391.5078),Vector2(680.5854, 347.8336),
Vector2(1150.439, 321.3172),Vector2(1295.61, 416.4644),
Vector2(1398.634, 453.8995),Vector2(1496.976, 453.8995),
Vector2(764.8781, 344.714),Vector2(847.6098, 413.3449),
Vector2(443.3171, 745.5806),Vector2(529.1707, 676.9497),
Vector2(444.8781, 232.409),Vector2(522.9268, 194.974),
Vector2(177.9512, 747.1404),Vector2(320.0001, 744.0208),
Vector2(632.1951, 641.0746),Vector2(704.0001, 639.5148),
Vector2(184.1951, 499.1335),Vector2(846.0489, 483.5356),
Vector2(179.5122, 246.4471),Vector2(321.561, 232.409),
Vector2(610.3415, 190.2946),Vector2(682.1464, 274.5234),
Vector2(181.0732, 124.7834),Vector2(524.4879, 123.2236),
Vector2(828.8781, 639.5148),Vector2(1294.049, 481.9757),
Vector2(179.5122, 623.9169),Vector2(527.6098, 605.1993),
Vector2(179.5122, 372.7903),Vector2(320.0001, 391.5078)]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Initialize buttons
	for i in range(6):
		var button_instance = button_scene.instantiate()
		button_instance.position = button_start_position + Vector2(0,i*125)
		add_child(button_instance)
	
	for i in range(16):
		var line_instance = line_scene.instantiate()
		line_instance.get_node("begin").position = line_pos[2*i]
		line_instance.get_node("end").position = line_pos[2*i+1]
		add_child(line_instance)
	#$line1.get_node("begin").position = Vector2(622.8293, 372.7903)
	#$line1.get_node("end").position = Vector2(736.7806, 296.3605)
	#$line2.get_node("begin").position = Vector2(808.5854, 491.3345)
	#$line2.get_node("end").position = Vector2(922.5367, 386.8284)
	#$line3.get_node("begin").position = Vector2(803.9025, 296.3605)
	#$line3.get_node("end").position = Vector2(936.5854, 672.2704)
	#$line4.get_node("begin").position = Vector2(1186.342, 291.6811)
	#$line4.get_node("end").position = Vector2(1242.537, 408.6655)
	#$line5.get_node("begin").position = Vector2(1002.146, 672.2704)
	#$line5.get_node("end").position = Vector2(1248.781, 489.7747)






func _process(delta: float) -> void:
	pass
	#print(get_global_mouse_position())


func _on_button_pressed() -> void:
	var line_instance = line_scene.instantiate()
	add_child(line_instance)
	pass # Replace with function body.
