extends Control

var ping_sent_time := 0.0
@onready var scores_label = $ScoresLabel
@onready var game_status_label = $GameStatusLabel
@onready var ping_label = $PingLabel

var ping_timer: Timer

func _ready():
	NetworkManager.scores_changed.connect(update_scores)
	
	ping_timer = Timer.new()
	ping_timer.wait_time = 1.0
	ping_timer.timeout.connect(send_ping)
	add_child(ping_timer)
	ping_timer.start()

	# The HUD will be updated automatically via scores_changed signal
	# so no need to call update_scores() here.

func send_ping():
	ping_sent_time = Time.get_ticks_msec()
	ping_request.rpc_id(1)

@rpc("any_peer", "call_local")
func ping_request():
	ping_response.rpc_id(multiplayer.get_remote_sender_id())

@rpc("authority", "call_local")
func ping_response():
	var rtt = Time.get_ticks_msec() - ping_sent_time
	ping_label.text = "Ping: %d ms" % rtt

@rpc("any_peer", "call_local")
func set_game_status(text):
	if is_instance_valid(game_status_label):
		game_status_label.text = text

func update_scores():
	if not is_instance_valid(scores_label):
		return
	var scores_text = "Scores:\n"
	# Sort players by score, descending
	var sorted_players = NetworkManager.players.values().duplicate()
	sorted_players.sort_custom(func(a, b): return a.score > b.score)

	for player_data in sorted_players:
		var player_name = player_data.nickname
		#if player_data.nickname == NetworkManager.my_nickname:
			#player_name += " (You)"
		scores_text += player_name + ": " + str(player_data.score) + "\n"
	scores_label.text = scores_text
