extends Node2D

const TANK_SCENE = preload("res://scenes/tank.tscn")
const BULLET_SCENE = preload("res://scenes/bullet.tscn")
const AMMO_UI_SCENE = preload("res://scenes/ammo_ui.tscn")

var bullet_counter = 0

const MAP_BOUNDS_X = Vector2(100, 800)
const MAP_BOUNDS_Y = Vector2(100, 600)

@onready var hud = $HUD
@onready var camera = $Camera2D
@onready var arena = $TileMapLayer

func _ready():
	if multiplayer.is_server():
		print("[DEBUG] Main scene ready on SERVER.")
		var my_id = multiplayer.get_unique_id()
		var my_nickname = NetworkManager.my_nickname
		NetworkManager.players[my_id] = {"nickname": my_nickname, "score": 0}
		NetworkManager.scores_changed.emit()
		spawn_player(my_id, my_nickname)
	else:
		print("[DEBUG] Main scene ready on CLIENT. Deferring registration call.")
		_client_ready_to_register.call_deferred()

func _client_ready_to_register():
	print("[DEBUG] CLIENT sending registration RPC to NetworkManager on server...")
	NetworkManager.register_player_rpc.rpc_id(1, NetworkManager.my_nickname)

@rpc("any_peer", "call_local")
func spawn_player(peer_id, nickname):
	print("[DEBUG-MAIN] Received request to spawn player. Peer:", peer_id, "Nickname:", nickname)
	if get_node_or_null("Players/" + str(peer_id)):
		print("[DEBUG-MAIN] Player already exists. Aborting spawn.")
		return
	print("[DEBUG-MAIN] Spawning tank for peer:", peer_id, "(" + nickname + ")")
	var tank = TANK_SCENE.instantiate()
	tank.add_to_group("tanks")
	tank.name = str(peer_id)
	tank.nickname = nickname
	$Players.add_child(tank)
	tank.position = Vector2(randi_range(100, 800), randi_range(100, 600))

	if peer_id == multiplayer.get_unique_id():
		var ammo_ui = AMMO_UI_SCENE.instantiate()
		hud.add_child(ammo_ui)
		tank.ammo_changed.connect(ammo_ui._on_ammo_changed)
		tank.reloading_status_changed.connect(ammo_ui._on_reloading_status_changed)

@rpc("any_peer", "call_remote", "reliable")
func request_shoot(shooter_id, bullet_position, bullet_velocity):
	var caller_id = multiplayer.get_remote_sender_id()
	if caller_id != 0 and caller_id != shooter_id:
		print("Player ", caller_id, " tried to make player ", shooter_id, " shoot. Denied.")
		return
	
	var bullet_name = "bullet_" + str(bullet_counter)
	bullet_counter += 1
	_spawn_bullet_on_all_peers.rpc(shooter_id, bullet_position, bullet_velocity, bullet_name)

@rpc("any_peer", "call_local", "reliable")
func _spawn_bullet_on_all_peers(shooter_id, bullet_position, bullet_velocity, bullet_name):
	var bullet = BULLET_SCENE.instantiate()
	bullet.name = bullet_name
	bullet.position = bullet_position
	bullet.init(shooter_id, bullet_velocity)
	add_child(bullet)

@rpc("any_peer", "call_local")
func remove_player(peer_id):
	var tank = get_node_or_null("Players/" + str(peer_id))
	if tank:
		tank.queue_free()

@rpc("any_peer", "call_local")
func spawn_explosion_rpc(position):
	var explosion = preload("res://scenes/explosion.tscn").instantiate()
	explosion.position = position
	add_child(explosion)
	explosion.emitting = true
