extends Node2D

@onready var display: Label = $Display
var target_number: String = ""  # 目标数字
var is_new_input

func _ready():
	# 生成一个 4 位随机数字
	target_number = _generate_random_number()
	print("目标数字: ", target_number)  # 调试用，正式游戏时可以去掉

	# 连接所有按钮的 pressed 信号
	for button in $Buttons.get_children():
		if button is Button:
			button.pressed.connect(_on_button_pressed.bind(button.text))

# 生成一个 4 位随机数字
func _generate_random_number() -> String:
	var number = ""
	for i in range(4):
		number += str(randi() % 10)  # 生成 0-9 的随机数字
	return number

func _on_button_pressed(button_text: String):
	if button_text == "C":
		display.text = "0"  # 清除显示
		is_new_input = true  # 重置为新输入
	elif button_text == "<":
		_on_enter_pressed()  # 处理确认逻辑
		is_new_input = true  # 设置为新输入
	else:
		if is_new_input or display.text == "0000":
			display.text = button_text  # 开始新的输入
			is_new_input = false  # 重置标志
		elif display.text.length() < 4:  # 限制输入长度为 4 位
			display.text += button_text

func _on_enter_pressed():
	var user_input = display.text
	if user_input.length() != 4:
		$Label.text = "请输入4位数字！"
		return
	else:
		$Label.text = ""

	# 初始化标记数组
	var target_matched = [false, false, false, false]  # 目标数字是否被匹配
	var input_matched = [false, false, false, false]   # 用户输入是否被匹配

	var full_match = 0  # 全对数量
	var half_match = 0  # 半对数量

	# 先计算全对
	for i in range(4):
		if user_input[i] == target_number[i]:
			full_match += 1
			target_matched[i] = true  # 标记目标数字为已匹配
			input_matched[i] = true   # 标记用户输入为已匹配

	# 再计算半对
	for i in range(4):
		if not input_matched[i]:  # 如果用户输入的数字未被匹配
			for j in range(4):
				if not target_matched[j] and user_input[i] == target_number[j]:
					half_match += 1
					target_matched[j] = true  # 标记目标数字为已匹配
					input_matched[i] = true   # 标记用户输入为已匹配
					break  # 找到一个匹配后立即跳出内层循环

	# 更新灯光状态
	_update_lights(full_match, half_match)
	if full_match == 4:
		$Label.text = "门开了！"

	# 打印结果（调试用）
	print("全对: ", full_match, " 半对: ", half_match)
# 更新灯光状态
func _update_lights(full_match: int, half_match: int):
	var lights = $Lights.get_children()
	for i in range(4):
		if i < full_match:
			lights[i].texture = load("res://assets/light_green.png")  # 绿灯
		elif i < full_match + half_match:
			lights[i].texture = load("res://assets/light_yellow.png")  # 黄灯
		else:
			lights[i].texture = load("res://assets/light_red.png")  # 红灯
