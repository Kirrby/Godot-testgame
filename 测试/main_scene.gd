extends Node2D

# 金币场景（需要提前在场景中创建并保存为单独的场景文件）
@onready var coin_scene = load("res://coin.tscn")
@onready var item_list: ItemList = $ItemList
@onready var ball_scene = load("res://ball.tscn")
var player_name
var score
@onready var firebase = get_node("/root/Firebase")
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
var ball: Node2D = null
# 游戏开始时间
var game_start_time: float = 0.0
# 游戏是否结束
var is_game_over: bool = false

# UI 节点（需要在场景中创建并连接到脚本）
@onready var timer_label: Label = $UITimerLabel
@onready var game_over_label: Label = $UIGameOverLabel

func _ready():
	# 初始化游戏
	# 获取排行榜
	firebase.connect("upload",Callable(self,"on_score_upload"))
	#Firebase.get_leaderboard(_on_leaderboard_updated)

	start_game()

#func start_game():
	## 重置游戏状态
	#current_coin_index = 0
	#is_game_over = false
	#game_start_time = Time.get_ticks_msec() / 1000.0  # 记录游戏开始时间
	#game_over_label.visible = false  # 隐藏游戏结束提示
#
	## 生成第一个金币
	#spawn_coin()

func start_game():
	# 重置所有游戏状态
	current_coin_index = 0
	is_game_over = false
	game_start_time = Time.get_ticks_msec() / 1000.0
	score = 0.0
	
	# 清理旧的金币实例
	if current_coin != null && is_instance_valid(current_coin):
		current_coin.queue_free()
		current_coin = null

	if ball != null && is_instance_valid(ball):
		ball.queue_free()
		ball = null

	# 重置UI状态
	game_over_label.visible = false
	$LineEdit.visible = false
	$Enter.visible = false
	$ItemList.visible = false
	$Refresh.visible = false
	$Restart.visible = false
	$Label.visible = false
	timer_label.text = "Time: 0.0"
	
	# 生成新金币
	spawn_coin()  
	ball = ball_scene.instantiate()
	ball.position = Vector2(470.0,91.0)
	add_child(ball)

	

#func spawn_coin():
	## 如果所有金币已经生成完毕，结束游戏
	#if current_coin_index >= coin_positions.size():
		#end_game()
		#return
#
	## 生成金币实例
	#current_coin = coin_scene.instantiate()
	#current_coin.position = coin_positions[current_coin_index]
	#add_child(current_coin)
#
	## 连接金币的碰撞信号
	#current_coin.connect("body_entered", _on_coin_body_entered)

func spawn_coin():
	# 如果所有金币已经生成完毕，结束游戏
	if current_coin_index >= coin_positions.size():
		end_game()
		return

	# 生成金币实例
	current_coin = coin_scene.instantiate()
	current_coin.position = coin_positions[current_coin_index]
	add_child(current_coin)

	# 使用 call_deferred 延迟连接金币的碰撞信号
	current_coin.call_deferred("connect", "body_entered", Callable(self, "_on_coin_body_entered"))

func _on_coin_body_entered(body: Node):
	# 检测是否是小球碰到了金币
	if body.is_in_group("ball"):  # 假设小球的节点名是 "Ball"
		# 销毁当前金币
		current_coin.queue_free()
		current_coin_index += 1  # 移动到下一个金币位置
		call_deferred("spawn_coin")  # 生成下一个金币

func _process(_delta: float):
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
	$LineEdit.visible = true
	$Enter.visible = true
	score = (Time.get_ticks_msec() / 1000.0 - game_start_time)  # 转换为整数分数
	
	
func _on_leaderboard_updated(scores: Array):
	item_list.clear()  # 清空列表
	for i in scores.size():
		var entry = scores[i]
		print("Number%d: %s - %.2fS" % [i+1, entry.name, entry.score])
		item_list.add_item("Number%d: %s - %.2fS" % [i+1, entry.name, entry.score])


func _on_button_pressed() -> void:
	$LineEdit.visible = false
	$Enter.visible = false
	$ItemList.visible = true
	$Refresh.visible = true
	$Label.visible = true
	$Restart.visible = true
	player_name = $LineEdit.text.strip_edges()
	if player_name == "":
		player_name = "Player1"  # 如果玩家未输入姓名，使用默认值
	Firebase.upload_score(player_name, score)
	$Label.text = "Uploading your scores..."
	pass # Replace with function body.

func on_score_upload(code):
	if code == 200:
		$Label.text = "Get online leaderboards"
		Firebase.get_leaderboard(_on_leaderboard_updated)
	pass


func _on_button_2_pressed() -> void:
	$LineEdit.visible = false
	$Enter.visible = false
	$ItemList.visible = false
	$Label.visible = false
	$Refresh.visible = false
	$Restart.visible = false
	start_game()
	pass # Replace with function body.


func _on_refresh_pressed() -> void:
	$Label.text = "Sorry,plase wait a minute..."
	Firebase.get_leaderboard(_on_leaderboard_updated)
	pass # Replace with function body.
