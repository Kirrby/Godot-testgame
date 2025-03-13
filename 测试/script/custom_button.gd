extends Button

# 按钮样式
var normal_style: StyleBoxFlat
var selected_style: StyleBoxFlat

func _ready():
	pass
	# 初始化普通样式
	#normal_style = StyleBoxFlat.new()
	#normal_style.bg_color = Color(0.2, 0.2, 0.2, 0.95)
	#normal_style.corner_radius_top_left = 10
	#normal_style.corner_radius_top_right = 10
	#normal_style.corner_radius_bottom_left = 10
	#normal_style.corner_radius_bottom_right = 10
	#
	# 初始化选中样式
	#selected_style = StyleBoxFlat.new()
	#selected_style.bg_color = Color(0.3, 0.3, 0.3, 1.0)
	#selected_style.border_width_left = 2
	#selected_style.border_width_top = 2
	#selected_style.border_width_right = 2
	#selected_style.border_width_bottom = 2
	#selected_style.border_color = Color(1, 0.7, 0)
	#selected_style.corner_radius_top_left = 10
	#selected_style.corner_radius_top_right = 10
	#selected_style.corner_radius_bottom_left = 10
	#selected_style.corner_radius_bottom_right = 10
	
	# 应用默认样式
	#$StyleBox.add_theme_stylebox_override("panel", normal_style)

# 设置按钮文本
func _set_text(text: String):
	$Label.text = text

# 设置按钮大小
func set_button_size(button_size: Vector2):
	custom_minimum_size = button_size
	$TextureRect.size = button_size
	$ColorRect.size = button_size
# 设置模糊程度
func set_blur_amount(amount: float):
	pass
	#material.set_shader_parameter("lod", amount)

# 设置选中状态
func set_selected(selected: bool):
	pass
	#if selected:
		#if selected_style:
			#$StyleBox.add_theme_stylebox_override("panel", selected_style)
			#$Label.add_theme_color_override("font_color", Color(1, 0.7, 0))
	#else:
		#if normal_style:
			#$StyleBox.add_theme_stylebox_override("panel", normal_style)
			#$Label.remove_theme_color_override("font_color")
		#$Label.remove_theme_color_override("font_color")
