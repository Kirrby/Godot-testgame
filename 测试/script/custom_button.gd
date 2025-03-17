extends Button

func _ready():
	pivot_offset = custom_minimum_size / 2
	$Thumbnail.position = Vector2(19.25, 75)

func _set_text(text: String):
	$Label.text = text

func set_button_size(button_size: Vector2):
	custom_minimum_size = button_size
	$ColorRect.size = button_size

func set_selected(_selected: bool):
	pass


func set_thumbnail(texture: Texture2D) -> void:
	$Thumbnail.texture = texture
	$Thumbnail.visible = true
	$Label.visible = false  # 聚焦时隐藏文字

func clear_thumbnail() -> void:
	$Thumbnail.visible = false
	$Label.visible = true   # 非聚焦时显示文字
	$Thumbnail.texture = null
