extends Camera2D

var view: int = 1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	zoom = Vector2.ONE * view
	pass

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed:

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			if view <= 64:
				view = (view * 2)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if view >= 2:
				view = (view / 2)
			elif view == 1:
				pass



func _input(event):
	_CamMovement(event)

func _CamMovement(event):
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			offset -= Vector2(event.relative.x, event.relative.y)/view
