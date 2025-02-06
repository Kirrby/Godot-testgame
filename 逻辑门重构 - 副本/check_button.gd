extends CheckButton
var body
@onready var child :Area2D = $button_area
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func signal_output() -> bool:
	return button_pressed


func _on_toggled(toggled_on: bool) -> void:
	#if body != null:
		#body.get_parent()._on_begin_area_entered(child)
	pass # Replace with function body.


func _on_area_2d_area_entered(area: Area2D) -> void:
	body = area
	pass # Replace with function body.
