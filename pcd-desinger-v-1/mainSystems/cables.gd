
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

const boardSize: Vector2i = Vector2i(640, 400)
const boardOffset: Vector2 = Vector2((1920 - 640) * 0.5, (1080 - 400) * 0.5)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			var startPos = snapToGrid(to_local(get_global_mouse_position()))
			
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
		var realMousePos = clampToBoard(to_local(get_global_mouse_position()))
		var diff = realMousePos - lastSnappedPos

		while abs(diff.x) >= snapPoint or abs(diff.y) >= snapPoint:
			var stepX = 0
			var stepY = 0
			if abs(diff.x) >= snapPoint:
				stepX = sign(diff.x) * snapPoint
			if abs(diff.y) >= snapPoint:
				stepY = sign(diff.y) * snapPoint
			var step = Vector2(stepX, stepY)
			if step == Vector2.ZERO:
				break
			var nextPos = clampToBoard(lastSnappedPos + step)
			if nextPos == lastSnappedPos:
				break
			lastSnappedPos = nextPos
			currentCable.addCableSegment(lastSnappedPos)
			diff = realMousePos - lastSnappedPos

		currentCable.update_active_point(lastSnappedPos)

func snapToGrid(pos: Vector2) -> Vector2:
	var localPos = pos - boardOffset
	var clamped_x = clampf(localPos.x, 0, boardSize.x)
	var clamped_y = clampf(localPos.y, 0, boardSize.y)

	var snapped_x = floor(clamped_x / dotDistance) * dotDistance + halfStep
	var snapped_y = floor(clamped_y / dotDistance) * dotDistance + halfStep
	snapped_x = clampf(snapped_x, halfStep, boardSize.x - halfStep)
	snapped_y = clampf(snapped_y, halfStep, boardSize.y - halfStep)

	return boardOffset + Vector2(snapped_x, snapped_y)

func clampToBoard(pos: Vector2) -> Vector2:
	var localPos = pos - boardOffset
	var clamped_x = clampf(localPos.x, halfStep, boardSize.x - halfStep)
	var clamped_y = clampf(localPos.y, halfStep, boardSize.y - halfStep)
	return boardOffset + Vector2(clamped_x, clamped_y)
