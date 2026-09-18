extends Camera2D

var view: float = 1

func _process(_delta: float) -> void:
	zoom = Vector2.ONE * pow(1.15,view)

func _input(event):
	_CamMovement(event)
	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			view = clamp(view + 1, 1, 64)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			view = clamp(view - 1, 1, 64)

func _CamMovement(event):
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			position = clamp(position - event.relative / zoom.x, Vector2(0,0), Vector2(100000,100000))
