extends Control

var current_chapter = 0
var chapters = [
	{
		"name": "第一章",
		"levels": ["1-1", "1-2", "1-3", "1-4", "1-5", "1-6", "1-7", "1-8", "1-9"]
	},
	{
		"name": "第二章",
		"levels": ["2-1", "2-2", "2-3", "2-4", "2-5"]
	},
	# 可以继续添加更多章节
]

func _ready():
	update_ui()
	
func update_ui():
	# 更新章节标题
	$ChapterPanel/ChapterLabel.text = chapters[current_chapter]["name"]
	
	# 更新关卡列表
	var level_container = $LevelPanel/ScrollContainer/LevelContainer
	# 清除现有关卡按钮
	for child in level_container.get_children():
		child.queue_free()
	
	# 添加新的关卡按钮
	for level in chapters[current_chapter]["levels"]:
		var button = Button.new()
		button.text = level
		button.custom_minimum_size = Vector2(100, 100)
		button.pressed.connect(_on_level_selected.bind(level))
		level_container.add_child(button)

func _on_prev_chapter():
	if current_chapter > 0:
		current_chapter -= 1
		update_ui()

func _on_next_chapter():
	if current_chapter < chapters.size() - 1:
		current_chapter += 1
		update_ui()

func _on_level_selected(level: String):
	# 在这里处理关卡选择逻辑
	print("选择关卡：", level)
	# 可以添加场景切换代码
	# get_tree().change_scene_to_file("res://scenes/levels/" + level + ".tscn")


func setup_level_scroll():
	var scroll = $LevelPanel/ScrollContainer
	var hbox = $LevelPanel/ScrollContainer/HBoxContainer
	
	# 设置滚动容器属性
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	
	# 设置滑动效果
	scroll.scroll_deadzone = 10
	scroll.follow_focus = true
	
	# 设置水平容器属性
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 20)  # 关卡按钮之间的间距
