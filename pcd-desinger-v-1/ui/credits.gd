extends Button
func _ready() -> void:

	pivot_offset = size / 2.0
	
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_mouse_entered() -> void:
		var tween = create_tween()
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.15)\
			.set_trans(Tween.TRANS_BACK)\
			.set_ease(Tween.EASE_OUT)

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
		


func _on_button_down() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.05)\
		.set_trans(Tween.TRANS_SINE)

func _on_button_up() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.1)\
		.set_trans(Tween.TRANS_BACK)
