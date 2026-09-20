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
enum DrawMode {Free, Line, Erase}
var currentMode: DrawMode = DrawMode.Free
var lineAxisLocked: bool = false
var lockedAxis: String = ""
var startPos: Vector2 = Vector2.ZERO
const boardSize: Vector2i = Vector2i(640, 400)
const boardOffset: Vector2 = Vector2((1920 - 640) * 0.5, (1080 - 400) * 0.5)

func _ready() -> void:
	Global.toolChanged.connect(GlobalToolChange)

func GlobalToolChange(toolName: String) -> void:
	if layingCable:
		if currentCable:
			currentCable.queue_free()
		layingCable = false
		currentCable = null
	match toolName:
		"FREE":
			currentMode = DrawMode.Free
		"LINE":
			currentMode = DrawMode.Line
		"ERASE":
			currentMode = DrawMode.Erase

func _input(event: InputEvent) -> void:
	if currentMode == DrawMode.Erase:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var mousePos = to_local(get_global_mouse_position())
			eraseCableAt(mousePos)
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			startPos = snapToGrid(to_local(get_global_mouse_position()))
			lineAxisLocked = false
			
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
		
		if currentMode == DrawMode.Line:
			if not lineAxisLocked:
				var initial_diff = realMousePos - startPos
				if initial_diff.length() >= snapPoint:
					lineAxisLocked = true
					var absX = abs(initial_diff.x)
					var absY = abs(initial_diff.y)
					var maxVal = max(absX, absY)
					var minVal = min(absX, absY)
					if minVal > maxVal * 0.414:
						lockedAxis = "d"
					elif absX > absY:
						lockedAxis = "x"
					else:
						lockedAxis = "y"
					
			if lineAxisLocked:
				if lockedAxis == "x":
					realMousePos.y = startPos.y
				elif lockedAxis == "y":
					realMousePos.x = startPos.x
				elif lockedAxis == "d":
					var initial_diff = realMousePos - startPos
					var size = round((abs(initial_diff.x) + abs(initial_diff.y)) * 0.5 / snapPoint) * snapPoint
					realMousePos.x = startPos.x + (sign(initial_diff.x) * size)
					realMousePos.y = startPos.y + (sign(initial_diff.y) * size)


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
			if currentCable.has_method("getPenultimatePoint") and currentCable.getPenultimatePoint() == nextPos:
				currentCable.removeLastCableSegment()
				lastSnappedPos = nextPos
			elif currentCable.has_method("checkPointsExists") and currentCable.checkPointExists(nextPos):
				break
			else:
				lastSnappedPos = nextPos
				currentCable.addCableSegment(lastSnappedPos)

			diff = realMousePos - lastSnappedPos

		currentCable.update_active_point(lastSnappedPos)

func eraseCableAt(target_pos: Vector2) -> void:
	var snapped_target = snapToGrid(target_pos)
	
	for i in range(SavedCables.size() - 1, -1, -1):
		var cable = SavedCables[i]
		if is_instance_valid(cable):
			if cable.has_node("Line2D"):
				var line = cable.get_node("Line2D") as Line2D
				for pt in line.points:
					if (cable.global_position + pt).distance_to(global_position + snapped_target) < 12.0:
						cable.queue_free()
						SavedCables.remove_at(i)
						return
			elif cable.position.distance_to(target_pos) < 24.0:
				cable.queue_free()
				SavedCables.remove_at(i)
				return

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
