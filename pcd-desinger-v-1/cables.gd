extends Node2D
const snapPoint: int = 8
var cableStart: Vector2 = Vector2.ZERO
var cableEnd: Vector2 = Vector2.ZERO
var layingCable: bool = false

func _draw() -> void:
	if layingCable or cableStart != cableEnd:
		draw_line(cableStart,cableEnd,Color(1,1,1,1), 2.0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			cableStart = snapToGrid(get_global_mouse_position())
			cableEnd =cableStart
			layingCable = true
			queue_redraw()
		elif layingCable:
			cableEnd = snapToGrid(get_global_mouse_position())
			layingCable = false
			queue_redraw()
	elif event is InputEventMouseMotion and layingCable:
		cableEnd = snapToGrid(get_global_mouse_position())
		queue_redraw()

func snapToGrid(pos: Vector2) -> Vector2:
	var localPos = to_local(pos)
	return (localPos / snapPoint).round() * snapPoint



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
