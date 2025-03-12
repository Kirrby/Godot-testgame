extends RigidBody2D

var xi
var yi

func _ready():
	# 初始化坐标系参数
	set_xy()
	
	# 生成碰撞多边形点数据
	var combined_points = generate_collision_points()
	
	# 创建并添加碰撞形状
	var collision_shape = CollisionPolygon2D.new()
	collision_shape.polygon = combined_points
	add_child(collision_shape)
	
	# 创建并添加可视化形状
	var visual_shape = create_visual_shape(combined_points)
	add_child(visual_shape)

func generate_collision_points() -> PackedVector2Array:
	var outer_radius = 200
	var inner_radius = 180
	var outer_points = []
	var inner_points = []
	
	# 生成外部碗壁点（0到180度）
	for i in range(33):
		var angle = PI * i / 64.0
		var x = outer_radius * cos(angle)
		var y = outer_radius * sin(angle)
		outer_points.append(Vector2(x * xi, y * yi))
	
	# 生成内部碗壁点（180到0度）
	for i in range(32, -1, -1):
		var angle = PI * i / 64.0
		var x = inner_radius * cos(angle)
		var y = inner_radius * sin(angle)
		inner_points.append(Vector2(x * xi, y * yi))
	
	return PackedVector2Array(outer_points + inner_points)

func create_visual_shape(points: PackedVector2Array) -> Polygon2D:
	# 创建可视化多边形
	var visual = Polygon2D.new()
	visual.polygon = points
	visual.color = Color.BLACK  # 设置填充颜色
	
	# 添加白色描边增强可见性
	#var outline = Line2D.new()
	#outline.points = points
	#outline.closed = true
	#outline.width = 2.0
	#outline.default_color = Color.WHITE
	#visual.add_child(outline)
	
	return visual

func set_xy():
	xi = -1  # X轴镜像
	yi = 1   # Y轴正常
