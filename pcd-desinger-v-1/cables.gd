
extends Node2D
const snapPoint: int = 8
var TraceScené: PackedScene = preload("res://trace.tscn")
var SavedCables: Array[Node2D] = []
var currentCable : Node2D = null
var layingCable: bool = false
var cableCounter: int = 0


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			var startPos = snapToGrid(get_global_mouse_position())
			
			currentCable = TraceScené.instantiate()
			add_child(currentCable)
			cableCounter += 1
			currentCable.setup_trace(startPos,startPos, cableCounter)
			layingCable = true
		elif layingCable:
			var endPos = snapToGrid(get_global_mouse_position())
			currentCable.update_end_point(endPos)
			var startPos = currentCable.getPointStart()
			if startPos != endPos:
				SavedCables.append(currentCable)
			else:
				currentCable.queue_free()
			layingCable = false
			currentCable = null
	elif event is InputEventMouseMotion and layingCable:
		var currentPos = snapToGrid(get_global_mouse_position())
		currentCable.update_end_point(currentPos)

func snapToGrid(pos: Vector2) -> Vector2:
	var localPos = to_local(pos)
	return (localPos / snapPoint).round() * snapPoint



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
