extends ItemList


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

var scroll_speed = 10
func _on_ItemList_gui_input(event):
	if event is InputEventScreenDrag:
		$ItemList.scroll_vertical -= event.relative.y * scroll_speed
