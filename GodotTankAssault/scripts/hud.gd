extends Control

@onready var scores_label = $ScoresLabel
@onready var game_status_label = $GameStatusLabel

func _ready():
	NetworkManager.scores_changed.connect(update_scores)
	update_scores()

@rpc("any_peer", "call_local")
func set_game_status(text):
	game_status_label.text = text

func update_scores():
	var scores_text = "Scores:\n"
	for peer_id in NetworkManager.scores:
		scores_text += "Player " + str(peer_id) + ": " + str(NetworkManager.scores[peer_id]) + "\n"
	scores_label.text = scores_text
