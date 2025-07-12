extends Node

signal scores_changed
signal game_found(host_ip)

const TANK_SCENE = preload("res://scenes/tank.tscn")
const PORT = 9999
const BROADCAST_PORT = 9998
const BROADCAST_INTERVAL = 1.0
const BROADCAST_MSG = "tank_assault_game"

var peer
var scores = {}

var broadcast_peer: PacketPeerUDP
var broadcast_timer: Timer

func _ready():
	multiplayer.peer_connected.connect(player_connected)
	multiplayer.peer_disconnected.connect(player_disconnected)
	multiplayer.connected_to_server.connect(connected_ok)
	multiplayer.connection_failed.connect(connected_fail)
	multiplayer.server_disconnected.connect(server_disconnected)

	broadcast_peer = PacketPeerUDP.new()
	broadcast_timer = Timer.new()
	broadcast_timer.wait_time = BROADCAST_INTERVAL
	broadcast_timer.timeout.connect(_on_broadcast_timer_timeout)
	add_child(broadcast_timer)

func _process(delta):
	if broadcast_peer.get_available_packet_count() > 0:
		var packet = broadcast_peer.get_packet()
		var sender_ip = broadcast_peer.get_packet_ip()
		var msg = packet.get_string_from_utf8()
		if msg == BROADCAST_MSG:
			game_found.emit(sender_ip)

func create_server():
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	if error != OK:
		print("Cannot create server.")
		return
	multiplayer.set_multiplayer_peer(peer)
	print("Server created. Waiting for players...")
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	
	_start_broadcasting()

func connect_to_server(ip_address: String):
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, PORT)
	multiplayer.set_multiplayer_peer(peer)

func add_player(peer_id):
	var main_scene = get_tree().get_root().get_node_or_null("Main")
	if main_scene:
		main_scene.spawn_player(peer_id)


@rpc("any_peer", "call_local")
func update_score(peer_id, amount):
	if scores.has(peer_id):
		scores[peer_id] += amount
		scores_changed.emit()

func _start_broadcasting():
	# No need to bind for broadcasting, only for listening.
	# The OS will assign an ephemeral port for sending.
	print("Started broadcasting game to port ", BROADCAST_PORT)
	broadcast_peer.set_broadcast_enabled(true)
	broadcast_timer.start()

func _stop_broadcasting():
	broadcast_timer.stop()
	broadcast_peer.close()

func _on_broadcast_timer_timeout():
	var msg_bytes = BROADCAST_MSG.to_utf8_buffer()
	broadcast_peer.set_dest_address("255.255.255.255", BROADCAST_PORT)
	broadcast_peer.put_packet(msg_bytes)
	
func find_games():
	broadcast_peer.close()
	if broadcast_peer.bind(BROADCAST_PORT) != OK:
		print("Error binding for broadcasts")

# --- Signal Callbacks ---

func player_connected(id):
	print("Player " + str(id) + " connected.")
	if multiplayer.is_server():
		# 不要先调用 add_player，这会直接 spawn
		# 而是先把 ID 记录进分数列表
		scores[id] = 0

		# 然后只通过 spawn_player.rpc() 让所有人都创建这个玩家
		var main_scene = get_tree().get_root().get_node_or_null("Main")
		if main_scene:
			main_scene.spawn_player.rpc(id)



func player_disconnected(id):
	print("Player " + str(id) + " disconnected.")
	if scores.has(id):
		scores.erase(id)
		scores_changed.emit()
	var main_scene = get_tree().get_root().get_node_or_null("Main")
	if main_scene:
		main_scene.remove_player(id)

func connected_ok():
	print("Successfully connected to server.")
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	_stop_broadcasting()

@rpc("any_peer")
func client_ready_to_receive_players():
	var new_peer_id = multiplayer.get_remote_sender_id()
	print("Client " + str(new_peer_id) + " is ready.")
	# Tell the new player to spawn all existing players.
	for existing_peer_id in scores.keys():
		var main_scene = get_tree().get_root().get_node_or_null("Main")
		if main_scene:
			main_scene.spawn_player.rpc_id(new_peer_id, existing_peer_id)

func connected_fail():
	print("Failed to connect to server.")
	multiplayer.set_multiplayer_peer(null)

func server_disconnected():
	print("Disconnected from server.")
	multiplayer.set_multiplayer_peer(null)
	scores.clear()
	get_tree().change_scene_to_file("res://scenes/network_ui.tscn")
