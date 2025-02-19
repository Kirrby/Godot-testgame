extends Node
const FIREBASE_URL = "https://godot-test-e5193-default-rtdb.firebaseio.com"
const API_KEY = "AIzaSyALdRg0qxP8SmYhwbNQwwIiNtgUF415H3M" # 你的apiKey
signal upload(code)

# 上传分数
func upload_score(player_name: String, score: float):
	var endpoint = FIREBASE_URL + "/scores.json?auth=%s" % API_KEY
	var data = {
		"name": player_name,
		"score": score,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_upload_completed)
	
	var error = http_request.request(
		endpoint,
		["Content-Type: application/json"],
		HTTPClient.METHOD_POST,
		JSON.stringify(data)
	)
	if error != OK:
		push_error("请求失败: " + str(error))


func _on_upload_completed(_result: int, code: int, _headers: PackedStringArray, _body: PackedByteArray):
	print("上传结果: HTTP ", code)
	if code == 200:
		print("上传成功")
	upload.emit(code)
# 获取排行榜
func get_leaderboard(callback: Callable) -> void:
	var endpoint = FIREBASE_URL + "/scores.json?orderBy=\"score\"&limitToFirst=100&auth=%s" % API_KEY
	#var endpoint = FIREBASE_URL + "/scores.json?orderBy=\"score\"&limitToLast=10&auth=%s" % API_KEY
	var http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_leaderboard_received.bind(callback))
	
	var error = http_request.request(endpoint)
	if error != OK:
		push_error("请求失败: " + str(error))
func _on_leaderboard_received(_result: int, code: int, _headers: PackedStringArray, body: PackedByteArray, callback: Callable):
	var response = body.get_string_from_utf8()
	if code == 200:
		var data = JSON.parse_string(response)
		var sorted_scores = []
		# 提取并排序数据
		if data is Dictionary:
			for key in data:
				var entry = data[key]
				sorted_scores.append({
					"name": entry.name,
					"score": entry.score
				})
			sorted_scores.sort_custom(func(a, b): return a.score < b.score)
		callback.call(sorted_scores)
	else:
		print("获取排行榜失败: ", response)
