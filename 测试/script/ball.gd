extends RigidBody2D

# 加速度的大小
const ACCELERATION_MAGNITUDE = 350
const SCALE_SPEED = 30  # 大小变化的速度
const MAX_SCALE = 2.0    # 最大放大倍数
const MIN_SCALE = 1.0    # 原始大小

var normal : Vector2
var initial_mechanical_energy: float = 0.0
var energy_loss
var is_on_floor
var is_on_U
var dir
var is_space_pressed = false
var is_in_shape

func _ready():
	# 设置物理材质
	var ball_material = PhysicsMaterial.new()
	ball_material.friction = 0.0
	ball_material.bounce = 0.0
	physics_material_override = ball_material
	initial_mechanical_energy = calculate_mechanical_energy()

func _process(_delta: float) -> void:
	#print(is_on_floor)
	#print(normal)
	pass

func _physics_process(delta: float) -> void:
	# 计算当前机械能
	var current_mechanical_energy = calculate_mechanical_energy()
	# 计算机械能损失
	energy_loss = initial_mechanical_energy - current_mechanical_energy
	# 如果机械能损失大于 0，补偿动能
	if energy_loss > 1000:
		compensate_kinetic_energy(energy_loss)

	if is_on_U:
		var acceleration = -normal * 90
		apply_central_impulse(acceleration)
	# 处理小球大小的变化
	if is_space_pressed:
		# 按住空格时，小球大小线性变大
		scale = scale.lerp(Vector2(MAX_SCALE, MAX_SCALE), SCALE_SPEED * delta)
		physics_material_override.bounce = 1.0  # 设置为完全弹性碰撞
	else:
		# 松开空格时，小球大小线性恢复
		scale = scale.lerp(Vector2(MIN_SCALE, MIN_SCALE), SCALE_SPEED * delta)
		physics_material_override.bounce = 0.0  # 恢复为无弹性碰撞

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		if is_on_floor or is_in_shape:  # 按下空格键
			var acceleration = normal * ACCELERATION_MAGNITUDE
			apply_central_impulse(acceleration)
		is_space_pressed = true
	elif event.is_action_released("jump"):
		is_space_pressed = false

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	# 在 _integrate_forces 中处理碰撞信息
	for i in range(state.get_contact_count()):
		var collision_normal = state.get_contact_local_normal(i)
		normal = collision_normal
		# 你可以在这里处理碰撞法线信息

func compensate_kinetic_energy(current_energy_loss: float) -> void:
	# 将损失的机械能补偿到动能中
	# 动能公式：E = 0.5 * m * v^2
	# 补偿后的动能：E_new = E_old + energy_loss
	# 因此，新的速度 v_new = sqrt((2 * (E_old + energy_loss)) / m)
	
	var current_kinetic_energy = 0.5 * mass * linear_velocity.length_squared()
	var new_kinetic_energy = current_kinetic_energy + current_energy_loss
	
	# 计算新的速度大小
	var new_speed = sqrt((2 * new_kinetic_energy) / mass)
	
	# 保持速度方向不变，调整速度大小
	linear_velocity = linear_velocity.normalized() * new_speed

func calculate_mechanical_energy() -> float:
	# 获取重力加速度
	var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	
	# 计算动能
	var kinetic_energy = 0.5 * mass * linear_velocity.length_squared()
	
	# 计算重力势能
	var potential_energy = mass * gravity * (600-position.y)
	#print(position.y)
	# 返回机械能
	return (kinetic_energy + potential_energy)/10

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("弯道"):
		is_on_U = true
	is_on_floor = true
	pass # Replace with function body.

func _on_body_exited(body: Node) -> void:
	if body.is_in_group("弯道"):
		is_on_U = false
	is_on_floor = false
	pass # Replace with function body.

#func _on_area_2d_body_entered(body: Node2D) -> void:
	#is_on_floor = true
	#normal = -normal
	#pass # Replace with function body.
#
#func _on_area_2d_body_exited(body: Node2D) -> void:
	#is_on_floor = false
	#normal = -normal
	#pass # Replace with function body.
#
#
#func _on_area_2d_2_body_entered(body: Node2D) -> void:
	#is_on_floor = true
	#pass # Replace with function body.
#
#
#func _on_area_2d_2_body_exited(body: Node2D) -> void:
	#is_on_floor = false
	#pass # Replace with function body.

func _on_area_2d_area_entered(_area: Area2D) -> void:
	is_in_shape = true
	pass # Replace with function body.


func _on_area_2d_area_exited(_area: Area2D) -> void:
	is_in_shape = false
	pass # Replace with function body.
