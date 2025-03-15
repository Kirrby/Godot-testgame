extends Control

var target_scroll := 0.0
var is_auto_scrolling := false
var card_width := 200
var focus_scale := 1.2
var current_focused_index := 0

var custom_button_scene = preload("res://scene/custom_button.tscn")

var chapters = [
	{"name": "第一章", "levels": range(1, 6)},
	{"name": "第二章", "levels": range(1, 6)},
	{"name": "第三章", "levels": range(1, 6)}
]

var current_chapter = 0
var is_dragging := false
var drag_start_position := Vector2()
var scroll_velocity := 0.0
var scroll_deceleration := 1000.0
var min_swipe_distance := 10
var is_valid_drag := false
var drag_threshold := 20

var wheel_timer := 0.0
var wheel_timeout := 0.2

var touch_start_time := 0

@onready var chapter_container = $ChapterContainer
@onready var level_scroll = $LevelScroll
@onready var level_container = $LevelScroll/LevelContainer

func _ready():
	# 初始化章节按钮
	for i in chapters.size():
		var button = custom_button_scene.instantiate()
		button.set_button_size(Vector2(180, 80))
		button._set_text(chapters[i].name)
		#button.set_blur_amount(2.0)
		button.pressed.connect(_on_chapter_selected.bind(i))
		if i == current_chapter:
			button.set_selected(true)
		chapter_container.add_child(button)
	_update_levels()

func _process(delta):
	if not is_dragging and abs(scroll_velocity) > 0:
		var new_scroll = level_scroll.scroll_horizontal - scroll_velocity * delta
		new_scroll = clamp(new_scroll, 0, level_scroll.get_h_scroll_bar().max_value)
		level_scroll.scroll_horizontal = new_scroll
		var deceleration = scroll_deceleration * delta
		scroll_velocity = move_toward(scroll_velocity, 0, deceleration)
		if abs(scroll_velocity) < 10:
			_auto_align_card()
		if wheel_timer > 0:
			wheel_timer -= delta
			if wheel_timer <= 0:
				_auto_align_card()


func _input(event: InputEvent) -> void:
	
	# 处理触摸事件
	if event is InputEventScreenTouch:
		
		if event.pressed:
			is_dragging = true
			drag_start_position = event.position
			scroll_velocity = 0
			# 新增点击检测变量
			touch_start_time = Time.get_ticks_msec()
			_set_buttons_mouse_filter(Control.MOUSE_FILTER_IGNORE)
		else:
			is_dragging = false
			_set_buttons_mouse_filter(Control.MOUSE_FILTER_PASS)
			
			# 新增点击检测逻辑
			var is_click = (
				(Time.get_ticks_msec() - touch_start_time) < 200 and
				drag_start_position.distance_to(event.position) < 20
			)
			
			if is_valid_drag:
				_auto_align_card()
			elif is_click:  # 新增点击处理分支
				_process_click(event.position)
				
			is_valid_drag = false
	
	# 处理拖动事件
	elif event is InputEventScreenDrag and is_dragging:
		var delta = event.position - drag_start_position
		
		if abs(delta.x) > drag_threshold:
			is_valid_drag = true
		
		if is_valid_drag:
			scroll_velocity = delta.x * 2
			var old_scroll = level_scroll.scroll_horizontal
			var new_scroll = old_scroll - delta.x
			new_scroll = clamp(new_scroll, 0, level_scroll.get_h_scroll_bar().max_value)
			level_scroll.scroll_horizontal = new_scroll
			drag_start_position = event.position
	
	# 处理鼠标滚轮
	if event is InputEventMouseButton:
		
		if event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
			var scroll_dir = "↑" if event.button_index == MOUSE_BUTTON_WHEEL_UP else "↓"
			
			var scroll_speed = 30.0
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				level_scroll.scroll_horizontal -= scroll_speed
			else:
				level_scroll.scroll_horizontal += scroll_speed
			
			wheel_timer = wheel_timeout
			_update_focus_effect()

# 新增的点击处理函数
func _process_click(click_pos: Vector2):
	for btn in level_container.get_children():
		var btn_rect = Rect2(btn.global_position, btn.size)
		if btn_rect.has_point(click_pos) and btn.mouse_filter == Control.MOUSE_FILTER_PASS:
			btn.emit_signal("pressed")
			break


func _handle_real_click(_click_pos: Vector2) -> void:
	# 转换坐标到全局视图坐标系
	var viewport := get_viewport()
	var global_pos := viewport.get_mouse_position()

	# 遍历所有关卡按钮
	for btn in level_container.get_children():
		# 获取按钮的实际显示范围
		var btn_rect := Rect2(
			btn.global_position,
			btn.size * btn.scale  # 考虑缩放后的实际大小
		)
		
		
		# 判断点击是否在按钮范围内
		if btn_rect.has_point(global_pos):
			# 触发按钮的按下信号
			btn.emit_signal("pressed")
			return

func _auto_align_card():
	if is_auto_scrolling:
		return
	
	# 获取精确的容器尺寸
	var content_width = level_container.size.x
	var viewport_width = level_scroll.size.x
	
	# 修正滚动范围计算：允许部分溢出
	var max_scroll = max(content_width - viewport_width + card_width * 0.5, 0)
	var center_x = viewport_width / 2
	
	# 查找最近卡片
	var min_distance = INF
	var target_index = 0
	for i in level_container.get_child_count():
		var card = level_container.get_child(i)
		var card_center = card.position.x + card.size.x / 2
		var distance = abs(card_center - (level_scroll.scroll_horizontal + center_x))
		if distance < min_distance:
			min_distance = distance
			target_index = i
	
	# 计算目标位置时允许边缘溢出
	var target_card = level_container.get_child(target_index)
	var target_center = target_card.position.x + target_card.size.x / 2
	var target_scroll = target_center - center_x
	
	# 调整clamp范围：允许第一个卡片左边缘溢出
	target_scroll = clamp(
		target_scroll,
		-card_width * 0.5,  # 允许向左溢出卡片宽度的一半
		max_scroll + card_width * 0.5  # 允许向右溢出
	)
	
	# 创建滚动动画
	var tween = create_tween()
	tween.tween_property(level_scroll, "scroll_horizontal", target_scroll, 0.3)\
		.set_ease(Tween.EASE_OUT)\
		.set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_update_card_states)
	is_auto_scrolling = true

func _update_card_states():
	is_auto_scrolling = false
	_update_focus_effect()

func _update_focus_effect():
	var center_x = level_scroll.size.x / 2 + level_scroll.scroll_horizontal
	for i in level_container.get_child_count():
		var card = level_container.get_child(i)
		var card_center = card.position.x + card.size.x / 2
		var distance = abs(card_center - center_x)
		
		
		# 动态缩放
		var target_scale = Vector2.ONE
		if distance < card_width:
			var lerp_weight = 1.0 - distance / card_width
			target_scale = Vector2.ONE.lerp(Vector2(focus_scale, focus_scale), lerp_weight)
		
		# 设置可点击状态
		card.mouse_filter = Control.MOUSE_FILTER_PASS if i == current_focused_index \
			else Control.MOUSE_FILTER_IGNORE
		
		# 平滑动画
		var tween = create_tween()
		tween.tween_property(card, "scale", target_scale, 0.2)

func _set_buttons_mouse_filter(filter):
	for btn in level_container.get_children():
		btn.mouse_filter = filter

func _on_chapter_selected(index: int):
	for i in chapter_container.get_child_count():
		chapter_container.get_child(i).set_selected(i == index)
	current_chapter = index
	_update_levels()

# 修改后的_update_levels方法
func _update_levels():
	for child in level_container.get_children():
		child.queue_free()
	
	var levels = chapters[current_chapter].levels
	
	# 添加起始占位卡片
	var start_spacer = _create_spacer_card()
	level_container.add_child(start_spacer)
	
	# 添加实际关卡卡片
	for level in levels:
		var button = custom_button_scene.instantiate()
		button._set_text(str(level))
		button.pressed.connect(_on_level_selected.bind(level))
		button.set_meta("is_real_card", true)  # 标记真实卡片
		level_container.add_child(button)
	
	# 添加结束占位卡片
	var end_spacer = _create_spacer_card()
	level_container.add_child(end_spacer)
	
	await get_tree().process_frame
	_auto_align_card()

func _create_spacer_card() -> Control:
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(275, 200)  # 宽度与正常卡片一致
	#spacer.visible = false  # 完全不可见
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE  # 不接收输入
	spacer.set_meta("is_spacer", true)  # 添加元数据标记
	return spacer

func _on_level_selected(level: int):
	var selected_index = level - chapters[current_chapter].levels[0]
	print("进入关卡：", current_chapter + 1, "-", level)
	get_tree().change_scene_to_file("res://scene/%d-%d.tscn" % [current_chapter + 1, level])
