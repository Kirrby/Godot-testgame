extends Control

@onready var bullet_container = $BulletContainer
@onready var reloading_label = $ReloadingLabel

func _ready():
	reloading_label.hide()

func _on_ammo_changed(ammo_count):
	for i in range(bullet_container.get_child_count()):
		bullet_container.get_child(i).visible = i < ammo_count

func _on_reloading_status_changed(is_reloading):
	if is_reloading:
		reloading_label.show()
		bullet_container.hide()
	else:
		reloading_label.hide()
		bullet_container.show()
