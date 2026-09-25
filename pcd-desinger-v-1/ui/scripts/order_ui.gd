extends Panel

@onready var panel: Panel = $"."

var open: bool
func _on_tab_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target_position: Vector2
		
		if open:
			target_position = position + Vector2(250, 0)
			open = false
			print("close", open)
		else:
			target_position = position - Vector2(250, 0)
			open = true
			print("open", open)
		
		var tween = create_tween()
		tween.set_trans(Tween.TransitionType.TRANS_QUAD)
		tween.set_ease(Tween.EaseType.EASE_OUT)
		tween.tween_property(panel, "position", target_position, 0.4)
