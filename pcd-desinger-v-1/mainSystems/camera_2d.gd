extends Camera2D

var view: float = 1.0
@export var move_speed: float = 400.0

func _process(delta: float) -> void:
	zoom = Vector2.ONE * pow(1.15, view)
	var input_dir := Vector2.ZERO
	if Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_S):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if input_dir != Vector2.ZERO:
		position += input_dir.normalized() * (move_speed / zoom.x) * delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			view = clamp(view + 1, 1, 64)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			view = clamp(view - 1, 1, 64)

	_CamMovement(event)

func _CamMovement(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.is_mouse_button_pressed(MOUSE_BUTTON_MIDDLE):
			position = clamp(position - event.relative / zoom.x, Vector2(0, 0), Vector2(100000, 100000))
