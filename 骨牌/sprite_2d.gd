extends Sprite2D
# 定义信号
signal drag_state_changed(dragging)
# 拖拽标志
var drag = false
# 鼠标点击与组件原点的相对位置间隔
var mp = Vector2(0,0)
# Called when the node enters the scene tree for the first time.
@onready var my_sprite = get_node("../rect")
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	# 拖拽移动
	if drag:
		# 刷新自己的坐标位置
		self.position = get_global_mouse_position() - mp
	pass
 
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			# 判断鼠标按钮是否在自己组件范围内
			if self.get_rect().has_point(to_local(event.position)):
				# 设置拖拽标志
				drag = true;
				# 记录相对位置
				mp = event.position - self.position
				emit_signal("drag_state_changed", drag)
		# 鼠标按键松开,则取消拖拽
		elif event.is_released():
			drag = false;
			emit_signal("drag_state_changed", drag)
		pass


func _on_drag_state_changed(dragging: Variant) -> void:
	if !dragging:
		if my_sprite.drag and self.get_rect().has_point(to_local(get_viewport().get_mouse_position())):
			self.position = my_sprite.position
	pass # Replace with function body.


func _on_bone_drag_state_changed(dragging: Variant) -> void:
	pass # Replace with function body.
