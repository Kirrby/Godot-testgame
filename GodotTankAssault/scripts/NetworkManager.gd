extends Node

signal scores_changed
signal game_found(host_ip)

const SERVER_PORT = 9999
const BROADCAST_PORT = 9998
const BROADCAST_INTERVAL = 1.0
const BROADCAST_MSG = "tank_assault_game"

var peer
var players = {} # { peer_id: {"nickname": "name", "score": 0} }
var my_nickname = ""

var broadcast_peer: PacketPeerUDP
var broadcast_timer: Timer

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

	broadcast_peer = PacketPeerUDP.new()
	broadcast_timer = Timer.new()
	broadcast_timer.wait_time = BROADCAST_INTERVAL
	broadcast_timer.timeout.connect(_on_broadcast_timer_timeout)
	add_child(broadcast_timer)

func _process(_delta):
	if broadcast_peer.get_available_packet_count() > 0:
		var packet = broadcast_peer.get_packet()
		var sender_ip = broadcast_peer.get_packet_ip()
		var msg = packet.get_string_from_utf8()
		if msg == BROADCAST_MSG:
			game_found.emit(sender_ip)

func create_server(nickname: String):
	my_nickname = nickname
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(SERVER_PORT)
	if error != OK:
		print("Cannot create server.")
		return
	multiplayer.set_multiplayer_peer(peer)
	print("Server created. Waiting for players...")
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	_start_broadcasting()

func connect_to_server(ip_address: String, nickname: String):
	my_nickname = nickname
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, SERVER_PORT)
	multiplayer.set_multiplayer_peer(peer)

# --- Player and Score Management ---

func award_point(peer_id):
	if not multiplayer.is_server(): return
	if players.has(peer_id):
		players[peer_id].score += 1
		update_scores_rpc.rpc(players)

@rpc("any_peer", "call_local", "reliable")
func register_player_rpc(nickname):
	var peer_id = multiplayer.get_remote_sender_id()
	print("[DEBUG] NetworkManager on SERVER received registration RPC from peer %d." % peer_id)
	handle_player_registration(peer_id, nickname)

func handle_player_registration(peer_id, nickname):
	print("[DEBUG-NET] SERVER: Handling registration for peer %d with nickname: %s" % [peer_id, nickname])
	players[peer_id] = {"nickname": nickname, "score": 0}

	var main = get_tree().get_root().get_node_or_null("Main")
	if not main: return

	# Tell everyone to spawn the new player
	main.spawn_player.rpc(peer_id, nickname)
	
	# Tell the new player about all existing players (including host)
	for existing_id in players:
		if existing_id != peer_id:
			main.spawn_player.rpc_id(peer_id, existing_id, players[existing_id].nickname)
	
	# Update scores on all clients
	update_scores_rpc.rpc(players)

@rpc("any_peer", "call_local", "reliable")
func update_scores_rpc(new_players_data):
	players = new_players_data
	scores_changed.emit()

# --- Broadcasting ---

func _start_broadcasting():
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

func _on_player_connected(id):
	print("Player %d connected." % id)

func _on_player_disconnected(id):
	print("Player %d disconnected." % id)
	if players.has(id):
		players.erase(id)
		update_scores_rpc.rpc(players)
		var main = get_tree().get_root().get_node_or_null("Main")
		if main:
			main.remove_player(id)

func _on_connected_ok():
	print("Successfully connected to server.")
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	_stop_broadcasting()

func _on_connection_failed():
	print("Failed to connect to server.")
	multiplayer.set_multiplayer_peer(null)

func _on_server_disconnected():
	print("Disconnected from server.")
	multiplayer.set_multiplayer_peer(null)
	players.clear()
	get_tree().change_scene_to_file("res://scenes/network_ui.tscn")
