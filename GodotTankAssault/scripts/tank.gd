extends CharacterBody2D

@export var move_speed: float = 200.0
@export var turn_speed: float = 2.5
@export var turret_turn_speed: float = 3.0
@export var bullet_speed: float = 1000.0
@export var max_health: int = 100
@export var health: int = max_health

var nickname: String = ""

@onready var turret = $Turret
@onready var muzzle = $Turret/Muzzle
@onready var health_bar = $HealthBar
@onready var body = $Body
@onready var name_bar: Label = $NameBar

var shoot_cooldown: Timer
var original_body_color
var original_turret_color

func _ready():
	original_body_color = body.color
	original_turret_color = turret.color
	health_bar.max_value = max_health
	health_bar.value = health
	shoot_cooldown = Timer.new()
	shoot_cooldown.name = "ShootCooldown"
	shoot_cooldown.wait_time = 0.5
	shoot_cooldown.one_shot = true
	add_child(shoot_cooldown)
	name_bar.text = nickname
	
	# Detach UI from parent's rotation
	health_bar.top_level = true
	name_bar.top_level = true

func _enter_tree() -> void:
	print("[DEBUG-TANK] Tank node with name '%s' entered the scene tree." % name)
	set_multiplayer_authority(name.to_int())

func _physics_process(delta):
	# Update UI position for all tanks on all clients
	health_bar.global_position = global_position + Vector2(-25,-40)
	name_bar.global_position = global_position + Vector2(-20,-60)
	
	if not is_multiplayer_authority():
		return
	
	var turret_direction = Input.get_axis("turret_left", "turret_right")
	var turn_direction = Input.get_axis("turn_left", "turn_right")
	var move_direction = Input.get_axis("move_backward", "move_forward")

	turret.rotation += turret_direction * turret_turn_speed * delta
	rotation += turn_direction * turn_speed * delta
	velocity = Vector2.UP.rotated(rotation) * move_direction * move_speed
	move_and_slide()

	if Input.is_action_just_pressed("shoot") and shoot_cooldown.is_stopped():
		var main_node = get_tree().root.get_node("Main")
		var bullet_velocity = Vector2.UP.rotated(turret.global_rotation) * bullet_speed
		var shooter_id = multiplayer.get_unique_id()
		var bullet_position = muzzle.global_position
		
		if multiplayer.is_server():
			main_node.request_shoot(shooter_id, bullet_position, bullet_velocity)
		else:
			main_node.request_shoot.rpc_id(1, shooter_id, bullet_position, bullet_velocity)
		
		play_shoot_sound_rpc.rpc()

@rpc("any_peer", "call_local")
func play_shoot_sound_rpc():
	$ShootSound.play()

@rpc("any_peer", "call_local", "reliable")
func take_damage_rpc(damage: int, attacker_id: int):
	health -= damage
	update_health_bar()
	if health <= 0:
		if multiplayer.is_server():
			NetworkManager.award_point(attacker_id)
		set_physics_process(false)
		hide()
		var main_node = get_tree().root.get_node("Main")
		main_node.spawn_explosion_rpc.rpc(global_position)
		destroy_tank_rpc.rpc()
	else:
		flash_white_rpc.rpc()

func update_health_bar():
	health_bar.value = health

const RESPAWN_TIME = 3.0

@rpc("any_peer", "call_local")
func destroy_tank_rpc():
	hide()
	$CollisionShape2D.set_deferred("disabled", true)
	var respawn_timer = get_tree().create_timer(RESPAWN_TIME)
	respawn_timer.timeout.connect(respawn_rpc)

@rpc("any_peer", "call_local")
func flash_white_rpc():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(body, "color", Color.WHITE, 0.1)
	tween.tween_property(turret, "color", Color.WHITE, 0.1)
	tween.tween_property(body, "color", original_body_color, 0.1).set_delay(0.1)
	tween.tween_property(turret, "color", original_turret_color, 0.1).set_delay(0.1)

@rpc("any_peer", "call_local")
func respawn_rpc():
	show()
	$CollisionShape2D.set_deferred("disabled", false)
	# This needs to be a valid position on the map
	global_position = Vector2(randi_range(100, 800), randi_range(100, 630))
	health = max_health
	update_health_bar()
	set_physics_process(true)
