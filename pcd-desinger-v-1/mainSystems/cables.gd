
extends Node2D
const snapPoint: int = 8
var TraceScene: PackedScene = preload("res://mainSystems/trace.tscn")
var SavedCables: Array[Node2D] = []
var currentCable : Node2D = null
var layingCable: bool = false
var cableCounter: int = 0
var lastSnappedPos: Vector2 = Vector2.ZERO
var dotDistance: int = 8
var halfStep = dotDistance * 0.5

const boardSize: Vector2i = Vector2i(640, 480)
const boardOffset: Vector2 = Vector2((1920 - 640) * 0.5, (1080 - 480) * 0.5)

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
			var nextPos = lastSnappedPos + step
			lastSnappedPos = clampToBoard(nextPos)
			currentCable.addCableSegment(lastSnappedPos)
			diff = realMousePos - lastSnappedPos
			
		currentCable.update_active_point(lastSnappedPos)

func snapToGrid(pos: Vector2) -> Vector2:
	var localPos = to_local(pos) - boardOffset
	var clamped_x = clampf(localPos.x, halfStep, boardSize.x - halfStep)
	var clamped_y = clampf(localPos.y, halfStep, boardSize.y - halfStep)
	var snapped_x = (floor((clamped_x - halfStep) / snapPoint) * snapPoint) + halfStep
	var snapped_y = (floor((clamped_y - halfStep) / snapPoint) * snapPoint) + halfStep
	return boardOffset + Vector2(snapped_x, snapped_y)

func clampToBoard(pos: Vector2) -> Vector2:
	var localPos = pos - boardOffset
	var clamped_x = clampf(localPos.x, halfStep, boardSize.x - halfStep)
	var clamped_y = clampf(localPos.y, halfStep, boardSize.y - halfStep)
	return boardOffset + Vector2(clamped_x, clamped_y)
