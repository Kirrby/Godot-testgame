extends CharacterBody2D

@export var move_speed: float = 200.0
@export var turn_speed: float = 2.5
@export var turret_turn_speed: float = 3.0
@export var max_health: int = 100
@export var health: int = max_health

@onready var turret = $Turret
@onready var muzzle = $Turret/Muzzle
@onready var multiplayer_synchronizer = $MultiplayerSynchronizer
@onready var health_bar = $HealthBar
@onready var body = $Body

var shoot_cooldown: Timer
var original_body_color
var original_turret_color

# This variable will only be used on the server instance of the tank.
# It stores the latest input state received for this tank.
var server_side_input = {"turret": 0, "turn": 0, "move": 0}

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
	update_health_rpc.rpc(health)

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _physics_process(delta):
	
	if not is_multiplayer_authority():
		return
	var peer_id = int(name)
	# --- Input Gathering (for the local player) ---
	# Every peer (client and server) is responsible for gathering input for its own tank.
	if multiplayer.get_unique_id() == peer_id:
		var turret_direction = Input.get_axis("turret_left", "turret_right")
		var turn_direction = Input.get_axis("turn_left", "turn_right")
		var move_direction = Input.get_axis("move_backward", "move_forward")
		
		var current_input = {
			"turret": turret_direction,
			"turn": turn_direction,
			"move": move_direction
		}
		
		turret.rotation += current_input["turret"] * turret_turn_speed * delta
		rotation += current_input["turn"] * turn_speed * delta
		velocity = Vector2.UP.rotated(rotation) * current_input["move"] * move_speed
		move_and_slide()
		health_bar.value = health

	# --- Shooting (initiated by local player, executed by server) ---
	if multiplayer.get_unique_id() == peer_id:
		if Input.is_action_just_pressed("shoot") and shoot_cooldown.is_stopped():
			var main_node = get_tree().root.get_node("Main")
			var bullet_velocity = Vector2.UP.rotated(turret.global_rotation) * 1000
			var shooter_id = peer_id
			var bullet_position = muzzle.global_position
			
			if multiplayer.is_server():
   				# The server calls the shoot function directly (no RPC needed for self)
				main_node.server_request_shoot(shooter_id, bullet_position, bullet_velocity)
			else:
				# A client must send an RPC to the server to request a shot
				main_node.server_request_shoot.rpc_id(1, shooter_id, bullet_position, bullet_velocity)

			play_shoot_sound_rpc.rpc()

	# --- Health Bar (All peers update their local view based on synced health) ---
	#health_bar.value = health

@rpc("any_peer", "call_local")
func play_shoot_sound_rpc():
	$ShootSound.play()

@rpc("call_remote")
func take_damage_rpc(damage: int):
	if not multiplayer.is_server():
		return
	update_health_rpc.rpc(health - damage)

@rpc("any_peer", "call_local")
func update_health_rpc(new_health: int):
	health = new_health
	health_bar.value = health
	if health <= 0:
		set_physics_process(false)
		hide()
		var main_node = get_tree().root.get_node("Main")
		main_node.spawn_explosion_rpc.rpc(global_position)
		destroy_tank_rpc.rpc()
	else:
		flash_white_rpc.rpc()

@rpc("any_peer", "call_local")
func destroy_tank_rpc():
	hide()
	# Disable collision to prevent dead tank from blocking bullets
	$CollisionShape2D.set_deferred("disabled", true)
	var respawn_timer = get_tree().create_timer(3.0)
	respawn_timer.timeout.connect(queue_free)

@rpc("any_peer", "call_local")
func flash_white_rpc():
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(body, "color", Color.WHITE, 0.1)
	tween.tween_property(turret, "color", Color.WHITE, 0.1)
	tween.tween_property(body, "color", original_body_color, 0.1).set_delay(0.1)
	tween.tween_property(turret, "color", original_turret_color, 0.1).set_delay(0.1)
