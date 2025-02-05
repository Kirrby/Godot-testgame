extends Node2D

# 金币场景（需要提前在场景中创建并保存为单独的场景文件）
@onready var coin_scene = load("res://coin.tscn")

# 金币生成位置的数组
@export var coin_positions: Array[Vector2] = [
	Vector2(800, 120),
	Vector2(550, 212),
	Vector2(235, 170),
	Vector2(800, 120),
	Vector2(550, 365),
	Vector2(235, 170),
	Vector2(725, 180),
	Vector2(115, 215),
	Vector2(550, 405),
	Vector2(550, 580),
	Vector2(550, 405)
]

# 当前金币的索引
var current_coin_index: int = 0
# 当前金币实例
var current_coin: Node2D = null

# 游戏开始时间
var game_start_time: float = 0.0
# 游戏是否结束
var is_game_over: bool = false

# UI 节点（需要在场景中创建并连接到脚本）
@onready var timer_label: Label = $UITimerLabel
@onready var game_over_label: Label = $UIGameOverLabel

func _ready():
	# 初始化游戏
	start_game()

func start_game():
	# 重置游戏状态
	current_coin_index = 0
	is_game_over = false
	game_start_time = Time.get_ticks_msec() / 1000.0  # 记录游戏开始时间
	game_over_label.visible = false  # 隐藏游戏结束提示

	# 生成第一个金币
	spawn_coin()

func spawn_coin():
	# 如果所有金币已经生成完毕，结束游戏
	if current_coin_index >= coin_positions.size():
		end_game()
		return

	# 生成金币实例
	current_coin = coin_scene.instantiate()
	current_coin.position = coin_positions[current_coin_index]
	add_child(current_coin)

	# 连接金币的碰撞信号
	current_coin.connect("body_entered", _on_coin_body_entered)

func _on_coin_body_entered(body: Node):
	# 检测是否是小球碰到了金币
	if body.name == "Ball":  # 假设小球的节点名是 "Ball"
		# 销毁当前金币
		current_coin.queue_free()
		current_coin_index += 1  # 移动到下一个金币位置
		spawn_coin()  # 生成下一个金币

func _process(delta: float):
	# 更新游戏时间
	if not is_game_over:
		var current_time = Time.get_ticks_msec() / 1000.0 - game_start_time
		timer_label.text = "Time: %.1f" % current_time
	#print(get_global_mouse_position())


func end_game():
	# 游戏结束逻辑
	is_game_over = true
	game_over_label.visible = true
	game_over_label.text = "Game Over!\nTime: %.1f" % (Time.get_ticks_msec() / 1000.0 - game_start_time)
