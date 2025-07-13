extends Control

@onready var ip_address_input = $VBoxContainer/IPAddressInput
@onready var game_list = $VBoxContainer/GameList
@onready var nickname_input = $VBoxContainer/NicknameInput
@onready var status_label = $VBoxContainer/StatusLabel

var found_games = {}

func _ready():
	NetworkManager.game_found.connect(_on_game_found)
	_on_refresh_button_pressed()

func _on_host_button_pressed():
	var nickname = nickname_input.text
	if nickname.is_empty():
		status_label.text = "请先输入你的名字"
		return
	NetworkManager.create_server(nickname)

func _on_join_button_pressed():
	var ip = ip_address_input.text
	var nickname = nickname_input.text
	print("[DEBUG] Join button pressed. Nickname: '%s', IP: '%s'" % [nickname, ip])
	if nickname.is_empty():
		status_label.text = "Please enter a nickname."
		return
	if ip.is_valid_ip_address():
		NetworkManager.connect_to_server(ip, nickname)
	else:
		status_label.text = "Invalid IP address entered."

func _on_refresh_button_pressed():
	game_list.clear()
	found_games.clear()
	NetworkManager.find_games()

func _on_game_list_item_selected(index):
	var ip = game_list.get_item_text(index)
	var nickname = nickname_input.text
	print("[DEBUG-UI] Game selected from list. Nickname: '%s', IP: '%s'" % [nickname, ip])
	if nickname.is_empty():
		status_label.text = "请先输入你的名字"
		return
	print("[DEBUG-UI] Connecting to server at", ip)
	NetworkManager.connect_to_server(ip, nickname)

func _on_game_found(host_ip):
	if !found_games.has(host_ip):
		found_games[host_ip] = true
		game_list.add_item(host_ip)
