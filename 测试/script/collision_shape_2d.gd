extends CollisionShape2D

func _ready() -> void:
	# 生成碗形的顶点数组
	var points = []
	var radius = 200
	var segments = 32
	
	# 只生成半圆形部分的顶点（180度）
	for i in range(segments + 1):
		var angle = PI * i / segments  # 0 到 PI
		var x = radius * cos(angle)
		var y = radius * sin(angle)
		points.append(Vector2(x, y))
	
	# 创建多边形形状
	var shape = CollisionPolygon2D.new()
	shape.polygon = PackedVector2Array(points)
	add_child(shape)
