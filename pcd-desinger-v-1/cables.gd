
extends Node2D
const snapPoint: int = 8
var TraceScene: PackedScene = preload("res://trace.tscn")
var SavedCables: Array[Node2D] = []
var currentCable : Node2D = null
var layingCable: bool = false
var cableCounter: int = 0
var lastSnappedPos: Vector2 = Vector2.ZERO

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			var startPos = snapToGrid(get_global_mouse_position())
			
			currentCable = TraceScene.instantiate()
			add_child(currentCable)
			cableCounter += 1
			currentCable.setup_trace(startPos, cableCounter)
			lastSnappedPos = startPos
			layingCable = true
		elif layingCable:
			var endPos = lastSnappedPos
			currentCable.update_active_point(endPos)
			if currentCable.getCableCount() > 2 or currentCable.getPointStart() != endPos:
				SavedCables.append(currentCable)
			else:
				currentCable.queue_free()
			layingCable = false
			currentCable = null
	elif event is InputEventMouseMotion and layingCable:
		var realMousePos = to_local(get_global_mouse_position())
		var diff = realMousePos - lastSnappedPos
		var thresshold = snapPoint * 0.5
		
		while abs(diff.x) >= thresshold or abs(diff.y) >= thresshold or (abs(diff.x) >= 4 and abs(diff.y) >= 4): 
			
			var stepX = sign(diff.x) * snapPoint if abs(diff.x) >= (4 if abs(diff.y) >= 4 else snapPoint) else 0
			var stepY = sign(diff.y) * snapPoint if abs(diff.y) >= (4 if abs(diff.x) >= 4 else snapPoint) else 0
			var step = Vector2(stepX, stepY)
			if step == Vector2.ZERO:
				break
			lastSnappedPos += step
			currentCable.addCableSegment(lastSnappedPos)
			diff = realMousePos - lastSnappedPos
			
		currentCable.update_active_point(lastSnappedPos)

func snapToGrid(pos: Vector2) -> Vector2:
	var localPos = to_local(pos)
	return (localPos / snapPoint).round() * snapPoint



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
