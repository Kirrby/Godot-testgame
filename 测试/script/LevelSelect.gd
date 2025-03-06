extends Control

# 预加载自定义按钮场景
var custom_button_scene = preload("res://scene/custom_button.tscn")

# 章节数据
var chapters = [
	{"name": "第一章", "levels": range(1, 11)},
	{"name": "第二章", "levels": range(1, 11)},
	{"name": "第三章", "levels": range(1, 11)}
]

# 当前选中的章节索引
var current_chapter = 0

@onready var chapter_container = $ChapterContainer
@onready var level_scroll = $LevelScroll
@onready var level_container = $LevelScroll/LevelContainer

# 滑动相关变量
var is_dragging = false
var drag_start_position = Vector2()
var scroll_velocity = 0.0
var scroll_deceleration = 1000.0  # 滑动减速度
var min_swipe_distance = 10  # 最小滑动距离

func _ready():
	# 初始化章节按钮
	for i in range(chapters.size()):
		var chapter = chapters[i]
		var button = custom_button_scene.instantiate()
		
		# 设置按钮属性
		button.set_button_size(Vector2(180, 80))
		button.set_text(chapter.name)
		button.set_blur_amount(2.0)
		button.pressed.connect(_on_chapter_selected.bind(i))
		
		# 设置当前选中章节的视觉效果
		if i == current_chapter:
			button.set_selected(true)
		
		chapter_container.add_child(button)
	
	# 初始化关卡按钮
	_update_levels()

func _process(delta):
	# 处理滑动惯性
	if not is_dragging and abs(scroll_velocity) > 0:
		var old_scroll = level_scroll.scroll_horizontal
		var new_scroll = old_scroll - scroll_velocity * delta
		
		# 边界检测
		new_scroll = clamp(new_scroll, 0, level_scroll.get_h_scroll_bar().max_value)
		
		level_scroll.scroll_horizontal = new_scroll
		
		# 应用减速度
		var deceleration = scroll_deceleration * delta
		if abs(scroll_velocity) <= deceleration:
			scroll_velocity = 0
		else:
			scroll_velocity = move_toward(scroll_velocity, 0, deceleration)

func _on_chapter_selected(index: int):
	# 更新视觉效果
	for i in range(chapter_container.get_child_count()):
		var button = chapter_container.get_child(i)
		button.set_selected(i == index)
	
	current_chapter = index
	_update_levels()

func _update_levels():
	# 清除现有关卡按钮
	for child in level_container.get_children():
		child.queue_free()
	
	# 创建新的关卡按钮
	var levels = chapters[current_chapter].levels
	for level in levels:
		var button = custom_button_scene.instantiate()
		
		# 设置按钮属性
		button.set_text(str(level))
		button.set_blur_amount(1.0)
		button.pressed.connect(_on_level_selected.bind(level))
		
		level_container.add_child(button)

func _on_level_selected(level: int):
	print("选择了第", current_chapter + 1, "章，第", level, "关")
	get_tree().change_scene_to_file("res://scene/" + str(current_chapter + 1) + "-" + str(level) + ".tscn")	# 在这里添加进入关卡的逻辑

func _input(event):
	if event is InputEventScreenTouch:
		if event.pressed:
			is_dragging = true
			drag_start_position = event.position
			scroll_velocity = 0  # 开始新的滑动时重置速度
		else:
			is_dragging = false
			# 计算滑动结束时的速度
			if abs(scroll_velocity) < min_swipe_distance:
				scroll_velocity = 0
	
	elif event is InputEventScreenDrag and is_dragging:
		var delta_x = event.position.x - drag_start_position.x
		scroll_velocity = delta_x * 2  # 根据滑动距离设置速度
		
		# 更新滚动位置
		var new_scroll = level_scroll.scroll_horizontal - delta_x
		new_scroll = clamp(new_scroll, 0, level_scroll.get_h_scroll_bar().max_value)
		level_scroll.scroll_horizontal = new_scroll
		
		drag_start_position = event.position
