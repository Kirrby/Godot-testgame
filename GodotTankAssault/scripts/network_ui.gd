extends Control

@onready var ip_address_input = $VBoxContainer/IPAddressInput
@onready var game_list = $VBoxContainer/GameList

var found_games = {}

func _ready():
	NetworkManager.game_found.connect(_on_game_found)
	_on_refresh_button_pressed()

func _on_host_button_pressed():
	NetworkManager.create_server()

func _on_join_button_pressed():
	var ip = ip_address_input.text
	if ip.is_valid_ip_address():
		NetworkManager.connect_to_server(ip)
	else:
		print("Invalid IP address entered.")

func _on_refresh_button_pressed():
	game_list.clear()
	found_games.clear()
	NetworkManager.find_games()

func _on_game_list_item_selected(index):
	var ip = game_list.get_item_text(index)
	NetworkManager.connect_to_server(ip)

func _on_game_found(host_ip):
	if !found_games.has(host_ip):
		found_games[host_ip] = true
		game_list.add_item(host_ip)
