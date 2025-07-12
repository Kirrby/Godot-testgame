extends Camera2D

var shake_tween: Tween

func shake(duration = 0.2, strength = 15.0):
	if shake_tween and shake_tween.is_running():
		shake_tween.kill()

	shake_tween = create_tween()
	shake_tween.set_parallel(true)
	shake_tween.tween_method(func(val): offset.x = val, strength, 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	shake_tween.tween_method(func(val): offset.y = val, strength, 0.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
