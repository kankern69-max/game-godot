extends Control

@export var min_zoom: float = 0.5
@export var max_zoom: float = 2.0
@export var zoom_factor: float = 0.1

var is_panning: bool = false

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_panning = event.pressed
			accept_event()
		
		if event.pressed:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_canvas(1.0 + zoom_factor, event.position)
				accept_event()
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_canvas(1.0 - zoom_factor, event.position)
				accept_event()

	elif event is InputEventMouseMotion and is_panning:
		position += event.relative
		accept_event()

func zoom_canvas(factor: float, mouse_pos: Vector2) -> void:
	var target_scale: Vector2 = (scale * factor).clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))
	if target_scale == scale:
		return
		
	var pivot: Vector2 = (mouse_pos - position) / scale
	scale = target_scale
	position = mouse_pos - pivot * scale
