extends logic


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if body != null and body2 != null:
		input = body.get_parent().signal_output()
		input2 = body2.get_parent().signal_output()
		signal_input(input)
		output = input or input2
		#print(input,input2,output)
	else:
		output = false
	pass
