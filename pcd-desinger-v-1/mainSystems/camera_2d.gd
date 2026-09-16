extends Camera2D

var view: float = 1

func _process(delta: float) -> void:
	zoom = Vector2.ONE * (pow(1.15,view))

func _input(event):
	_CamMovement(event)
	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if view <= 64:
				view = (view +1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if view >= 2:
				view = (view -1)
				pass

func _CamMovement(event):
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			position = clamp(position - Vector2(event.relative.x, event.relative.y)/view, Vector2(760, 340), Vector2(4000,4000))
