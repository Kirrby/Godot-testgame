extends Sprite2D
# 拖拽标志
var drag = false
var dragged = false
var connected = false
# 鼠标点击与组件原点的相对位置间隔
var mp = Vector2(0,0)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var my_sprite = get_node("../bone")
	pass
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# 拖拽移动
	if dragged and drag:
		texture = load("res://blue_1.png")
		if !drag:
			connected = true
	else:
		texture = load("res://black_1.png")

	pass
 
func _input(event):
	# 检查是否是鼠标移动事件
	if event is InputEventMouseMotion:
		# 获取当前节点的矩形区域
		var rect = self.get_rect()
		# 获取鼠标位置，并将其转换到当前节点的坐标系中
		var mouse_position = get_viewport().get_mouse_position()
		var local_mouse_position = to_local(mouse_position)
		
		# 检查鼠标位置是否在节点的矩形区域内
		if rect.has_point(local_mouse_position):
			# 如果鼠标在节点范围内，设置drag为true
			drag = true
		else:
			# 如果鼠标不在节点范围内，设置drag为false
			drag = false


func _on_bone_drag_state_changed(dragging: Variant) -> void:
	if dragging:
		dragged = true
	else:
		dragged = false
	pass # Replace with function body.


func _on_bone_2_drag_state_changed(dragging: Variant) -> void:
	pass # Replace with function body.
