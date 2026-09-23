extends Panel

@onready var panel: Panel = $"."
@onready var openCloseLabel: Label = $open_closeButton/Label

func _on_open_close_button_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target_position: Vector2
		
		if openCloseLabel.text == "<":
			target_position = Vector2(-250, 20)
			openCloseLabel.text = ">"
		elif openCloseLabel.text == ">":
			target_position = Vector2(20, 20)
			openCloseLabel.text = "<"
		else:
			push_error("Component ui open close broken!")
			return
		
		var tween = create_tween()
		tween.set_trans(Tween.TransitionType.TRANS_QUAD)
		tween.set_ease(Tween.EaseType.EASE_OUT)
		tween.tween_property(panel, "position", target_position, 0.4)
