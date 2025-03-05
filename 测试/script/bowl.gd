extends Node2D

var xi
var yi

func _ready():
	# 创建外部碗壁
	set_xy()
	var _outer_wall = CollisionPolygon2D.new()
	var outer_points = []
	var outer_radius = 200
	
	# 创建内部碗壁
	var _inner_wall = CollisionPolygon2D.new()
	var inner_points = []
	var inner_radius = 180  # 稍小的半径形成壁厚
	
	# 生成外部碗壁的点
	for i in range(33):  # 0到180度
		var angle = PI * i / 64.0
		var x = outer_radius * cos(angle)
		var y = outer_radius * sin(angle)
		outer_points.append(Vector2(x * xi, y * yi))
	
	# 生成内部碗壁的点（反向）
	for i in range(32, -1, -1):  # 180到0度
		var angle = PI * i / 64.0
		var x = inner_radius * cos(angle)
		var y = inner_radius * sin(angle)
		inner_points.append(Vector2(x * xi, y * yi))
	
	# 合并点创建空心碗
	var combined_points = outer_points + inner_points
	
	# 创建碰撞多边形
	var shape = CollisionPolygon2D.new()
	shape.polygon = PackedVector2Array(combined_points)
	add_child(shape)

func set_xy():
	xi = -1
	yi = 1
