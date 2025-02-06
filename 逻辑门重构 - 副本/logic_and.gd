extends logic

func _process(delta: float) -> void:
	if body != null and body2 != null:
		input = body.get_parent().signal_output()
		input2 = body2.get_parent().signal_output()
		signal_input(input)
		#print(input,input2,output)
		output = input and input2
	else:
		output = false
	pass
