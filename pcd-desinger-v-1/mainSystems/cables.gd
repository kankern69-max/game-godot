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
enum DrawMode {Free, Line, Erase, Select, ExtendedLine}
var currentMode: DrawMode = DrawMode.Free
var lineAxisLocked: bool = false
var lockedAxis: String = ""
var startPos: Vector2 = Vector2.ZERO
var editingCable: Node2D = null
var cableWayPoints: PackedVector2Array = []
var activeWayPointIndex: int = -1
var boardSize: Vector2i = Vector2i(640, 400)
var boardOffset: Vector2 = Vector2((1920 - 640) * 0.5, (1080 - 400) * 0.5)
var Astar: AStar2D = AStar2D.new()
 
func _ready() -> void:
	add_to_group("cables_manager")
	if Global.has_signal("toolChanged"):
		Global.toolChanged.connect(GlobalToolChange)
	setup_astar_grid()
 
func _process(_delta: float) -> void:
	for cable in SavedCables:
		if is_instance_valid(cable) and cable.has_method("check_battery_connection"):
			cable.check_battery_connection()
 
func setup_astar_grid() -> void:
	Astar.clear()
	var cols = int(boardSize.x / dotDistance)
	var rows = int(boardSize.y / dotDistance)
	
	for x in range(cols):
		for y in range(rows):
			var point_id = get_point_id(x, y)
			var world_pos = boardOffset + Vector2(x * dotDistance + halfStep, y * dotDistance + halfStep)
			Astar.add_point(point_id, world_pos)
 
	for x in range(cols):
		for y in range(rows):
			var current_id = get_point_id(x, y)
			
			var orthogonals = [
				Vector2i(x + 1, y),
				Vector2i(x - 1, y),
				Vector2i(x, y + 1),
				Vector2i(x, y - 1)
			]
			for n in orthogonals:
				if n.x >= 0 and n.x < cols and n.y >= 0 and n.y < rows:
					var neighbor_id = get_point_id(n.x, n.y)
					if not Astar.are_points_connected(current_id, neighbor_id):
						Astar.connect_points(current_id, neighbor_id, true)
						Astar.set_point_weight_scale(neighbor_id, 1.0)
 
			var diagonals = [
				Vector2i(x + 1, y + 1),
				Vector2i(x - 1, y + 1),
				Vector2i(x + 1, y - 1),
				Vector2i(x - 1, y - 1)
			]
			for n in diagonals:
				if n.x >= 0 and n.x < cols and n.y >= 0 and n.y < rows:
					var neighbor_id = get_point_id(n.x, n.y)
					if not Astar.are_points_connected(current_id, neighbor_id):
						Astar.connect_points(current_id, neighbor_id, true)
 
func get_point_id(x: int, y:int) -> int:
	var cols = int(boardSize.x / dotDistance)
	return x + y * cols
 
func GlobalToolChange(toolName: String) -> void:
	if layingCable:
		if currentCable and not editingCable:
			currentCable.queue_free()
		layingCable = false
		currentCable = null
		editingCable = null
		cableWayPoints.clear()
		activeWayPointIndex = -1
	match toolName:
		"FREE":
			currentMode = DrawMode.Free
		"LINE":
			currentMode = DrawMode.Line
		"ERASE":
			currentMode = DrawMode.Erase
		"SELECT":
			currentMode = DrawMode.Select
		"EXTENDEDLINE":
			currentMode = DrawMode.ExtendedLine
 
func _input(event: InputEvent) -> void:
	if currentMode == DrawMode.Select and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click_pos = to_local(get_global_mouse_position())
		var components = get_tree().get_nodes_in_group("circuit_components")
		for comp in components:
			if comp is Base_component:
				if comp.contains_point(to_global(click_pos)):
					if comp.has_method("toggle_state"):
						comp.toggle_state()
						notify_circuit_update()
						Base_component.update_all_circuits(get_tree())
						return
	
	if currentMode == DrawMode.Erase:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var mousePos = to_local(get_global_mouse_position())
			eraseCableAt(mousePos)
			notify_circuit_update()
			Base_component.update_all_circuits(get_tree())
		return
		
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			startPos = snapToGrid(to_local(get_global_mouse_position()))
			if currentMode == DrawMode.Select:
				var cableToEdit = findCableAt(startPos)
				if cableToEdit:
					editingCable = cableToEdit
					SavedCables.erase(editingCable)
					
					currentCable = editingCable
					lastSnappedPos = startPos
					layingCable = true
					
					setup_editing_waypoints(to_global(startPos))
					save_changed_points(startPos)
			else:
				lineAxisLocked = false
				currentCable = TraceScene.instantiate()
				add_child(currentCable)
				currentCable.set_cable_color(Global.CableColor)
				cableCounter += 1
				currentCable.setup_trace(startPos, cableCounter)
				lastSnappedPos = startPos
				layingCable = true
 
		elif layingCable:
			if is_instance_valid(currentCable):
				var endPos = lastSnappedPos
				if currentMode != DrawMode.Select and currentMode != DrawMode.ExtendedLine and currentCable.has_method("update_active_point"):
					currentCable.update_active_point(endPos)
					
				var line = _get_line2d(currentCable)
				var total_distance: float = 0.0
				if line and line.points.size() > 1:
					for i in range(line.points.size() - 1):
						total_distance += line.points[i].distance_to(line.points[i + 1])
				var cable_length = 0
				if currentCable.has_method("getCableCount"):
					cable_length = currentCable.getCableCount()
				elif currentCable.has_node("Line2D"):
					cable_length = (currentCable.get_node("Line2D") as Line2D).points.size()
					
				if cable_length > 1 and total_distance >= snapPoint:
					SavedCables.append(currentCable)
					notify_circuit_update()
					Base_component.update_all_circuits(get_tree())
				else:
					currentCable.queue_free()
				
			layingCable = false
			currentCable = null
			editingCable = null
			cableWayPoints.clear()
			activeWayPointIndex = -1
			
	elif event is InputEventMouseMotion and layingCable:
		var realMousePos = clampToBoard(to_local(get_global_mouse_position()))
		var targetPos = snapToGrid(realMousePos)
		
		if targetPos == lastSnappedPos and (currentMode == DrawMode.Free or currentMode == DrawMode.Select or currentMode == DrawMode.ExtendedLine):
			return
		
		if currentMode == DrawMode.Select and is_instance_valid(currentCable):
			save_changed_points(targetPos)
 
		elif currentMode == DrawMode.Free:
			var start_id = Astar.get_closest_point(startPos)
			var target_id = Astar.get_closest_point(targetPos)
			var path: PackedVector2Array = Astar.get_point_path(start_id, target_id)
			path = remove_path_loops(path)
			var line = _get_line2d(currentCable)
			if line:
				line.clear_points()
				for pt in path:
					line.add_point(currentCable.to_local(to_global(pt)))
					
			lastSnappedPos = targetPos
		
		elif currentMode == DrawMode.ExtendedLine:
			var path: PackedVector2Array = generate_extendedLine_path(startPos, targetPos)
			path = remove_path_loops(path)
			var line = _get_line2d(currentCable)
			if line:
				line.clear_points()
				for pt in path:
					line.add_point(currentCable.to_local(pt))
					
			if currentCable.has_method("update_active_point") and path.size() > 0:
				currentCable.update_active_point(currentCable.to_local(path[path.size() - 1]))
				
			lastSnappedPos = targetPos
		
		elif currentMode == DrawMode.Line:
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
				
				if lockedAxis == "d":
					stepX = sign(diff.x) * snapPoint
					stepY = sign(diff.y) * snapPoint
				else:
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
				if currentCable.has_method("getPenultimatePoint") and currentCable.getPenultimatePoint() == to_global(nextPos):
					currentCable.removeLastCableSegment()
					lastSnappedPos = nextPos
				elif currentCable.has_method("checkPointExists") and currentCable.checkPointExists(to_global(nextPos)):
					break
				else:
					lastSnappedPos = nextPos
					currentCable.addCableSegment(lastSnappedPos)
 
				diff = realMousePos - lastSnappedPos
 
			if currentCable.has_method("update_active_point"):
				currentCable.update_active_point(lastSnappedPos)

func remove_path_loops(path:PackedVector2Array) -> PackedVector2Array:
	var result: PackedVector2Array = []
	var visited_indices: Dictionary = {}
	for pt in path:
		var snapped = snapToGrid(pt)
		var key = Vector2i(round(snapped.x), round(snapped.y))
		if visited_indices.has(key):
			var loop_start_IDX: int =visited_indices[key]
			for i in range(result.size() - 1, loop_start_IDX, -1):
				var prev_snapped = snapToGrid(result[i])
				var prev_key = Vector2i(round(prev_snapped.x), round(prev_snapped.y))
				visited_indices.erase(prev_key)
				result.remove_at(i)
		else:
			visited_indices[key] = result.size()
			result.append(snapped)
	return result

func _get_line2d(cable: Node2D) -> Line2D:
	if cable is Line2D:
		return cable as Line2D
	elif cable.has_node("Line2D"):
		return cable.get_node("Line2D") as Line2D
	return null

func generate_extendedLine_path(from_pos: Vector2, to_pos: Vector2) -> PackedVector2Array:
	var raw_path: PackedVector2Array = []
	raw_path.append(from_pos)
	
	var delta = to_pos - from_pos
	
	if abs(delta.y) >= abs(delta.x):
		var step_y = sign(delta.y) * dotDistance
		if step_y == 0:
			return raw_path
			
		var total_rows = int(round(abs(delta.y) / dotDistance))
		if total_rows < 3:
			raw_path.append(clampToBoard(Vector2(from_pos.x, to_pos.y)))
			return raw_path
			
		var current_p = from_pos
		var extent = dotDistance * 2
		
		current_p.y += step_y
		raw_path.append(clampToBoard(current_p))
		
		var direction = 1
		current_p.x += extent * direction
		raw_path.append(clampToBoard(current_p))
		
		var rows_done = 1
		
		while rows_done < total_rows - 2:
			current_p.y += step_y
			raw_path.append(clampToBoard(current_p))
			
			direction *= -1
			current_p.x = from_pos.x + (extent * direction)
			raw_path.append(clampToBoard(current_p))
			
			rows_done += 1
			
		current_p.y += step_y
		raw_path.append(clampToBoard(current_p))
		
		current_p.x = from_pos.x
		raw_path.append(clampToBoard(current_p))
		
		current_p.y = to_pos.y
		raw_path.append(clampToBoard(current_p))
 
	else:
		var step_x = sign(delta.x) * dotDistance
		if step_x == 0:
			return raw_path
			
		var total_cols = int(round(abs(delta.x) / dotDistance))
		if total_cols < 3:
			raw_path.append(clampToBoard(Vector2(to_pos.x, from_pos.y)))
			return raw_path
			
		var current_p = from_pos
		var extent = dotDistance * 2
		
		current_p.x += step_x
		raw_path.append(clampToBoard(current_p))
		
		var direction = 1
		current_p.y += extent * direction
		raw_path.append(clampToBoard(current_p))
		
		var cols_done = 1
		
		while cols_done < total_cols - 2:
			current_p.x += step_x
			raw_path.append(clampToBoard(current_p))
			
			direction *= -1
			current_p.y = from_pos.y + (extent * direction)
			raw_path.append(clampToBoard(current_p))
			
			cols_done += 1
			
		current_p.x += step_x
		raw_path.append(clampToBoard(current_p))
		
		current_p.y = from_pos.y
		raw_path.append(clampToBoard(current_p))
		
		current_p.x = to_pos.x
		raw_path.append(clampToBoard(current_p))
 
	var full_grid_path: PackedVector2Array = []
	for i in range(raw_path.size() - 1):
		var p1 = raw_path[i]
		var p2 = raw_path[i + 1]
		var dist = p1.distance_to(p2)
		var steps = int(round(dist / dotDistance))
		
		for s in range(steps):
			var interpolated = p1.lerp(p2, float(s) / max(steps, 1))
			full_grid_path.append(snapToGrid(interpolated))
			
	if raw_path.size() > 0:
		full_grid_path.append(snapToGrid(raw_path[raw_path.size() - 1]))
		
	return full_grid_path
 
func findCableAt(target_pos: Vector2) -> Node2D:
	var snapped_target = snapToGrid(target_pos)
	for cable in SavedCables:
		if is_instance_valid(cable):
			if cable.has_node("Line2D"):
				var line = cable.get_node("Line2D") as Line2D
				for pt in line.points:
					if cable.to_global(pt).distance_to(to_global(snapped_target)) < 12.0:
						return cable
			elif cable.position.distance_to(target_pos) < 24.0:
				return cable
	return null
 
func eraseCableAt(target_pos: Vector2) -> void:
	var snapped_target = snapToGrid(target_pos)
	
	for i in range(SavedCables.size() - 1, -1, -1):
		var cable = SavedCables[i]
		if is_instance_valid(cable):
			if cable.has_node("Line2D"):
				var line = cable.get_node("Line2D") as Line2D
				for pt in line.points:
					if cable.to_global(pt).distance_to(to_global(snapped_target)) < 12.0:
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
 
func notify_circuit_update() -> void:
	get_tree().call_group("circuit_components", "rebuild_connections")
	_reset_circuit_power()
	get_tree().call_group("circuit_components", "update_simulation")
 
func _reset_circuit_power() -> void:
	for c in get_tree().get_nodes_in_group("cables"):
		if is_instance_valid(c) and c.has_method("set_powered"):
			c.set_powered(false)
 
	for comp in get_tree().get_nodes_in_group("circuit_components"):
		if is_instance_valid(comp):
			comp.is_powered = false
			comp.voltage = 0.0
			comp.current = 0.0

func setup_editing_waypoints(global_click_pos: Vector2) -> void:
	cableWayPoints.clear()
	activeWayPointIndex = -1
	if not is_instance_valid(editingCable):
		return
	if editingCable.get("waypoints") != null and editingCable.waypoints.size() >= 2:
		cableWayPoints = editingCable.waypoints.duplicate()
	else:
		var line = _get_line2d(editingCable)
		if not line or line.points.size() < 2:
			return
		var raw_global_points: PackedVector2Array = []
		for pt in line.points:
			raw_global_points.append(editingCable.to_global(pt))
		cableWayPoints = extract_corner_waypoints(raw_global_points)
	var closest_idx = -1
	var min_dist = 16.0
	for i in range(cableWayPoints.size()):
		var d = cableWayPoints[i].distance_to(global_click_pos)
		if d < min_dist:
			min_dist = d
			closest_idx = i
	if closest_idx != -1:
		activeWayPointIndex = closest_idx
	else:
		var best_segment_idx = 0
		var best_dist = INF
		for i in range(cableWayPoints.size() - 1):
			var p1 = cableWayPoints[i]
			var p2 = cableWayPoints[i + 1]
			var proj = Geometry2D.get_closest_point_to_segment(global_click_pos, p1, p2)
			var d = proj.distance_to(global_click_pos)
			if d < best_dist:
				best_dist = d 
				best_segment_idx = i
		activeWayPointIndex = best_segment_idx + 1
		cableWayPoints.insert(activeWayPointIndex, global_click_pos)
	editingCable.waypoints = cableWayPoints.duplicate()
	editingCable.legs = build_legs_from_waypoints(cableWayPoints)

func extract_corner_waypoints(points: PackedVector2Array) -> PackedVector2Array:
	
	if points.size() <= 2:
		return points.duplicate()
	var clean_points: PackedVector2Array = []
	clean_points.append(points[0])
	for i in range(1, points.size()):
		if points[i].distance_squared_to(clean_points[clean_points.size() - 1]) > 0.1:
			clean_points.append(points[i])
	if clean_points.size() <= 2:
		return clean_points
	var corners: PackedVector2Array = []
	corners.append(clean_points[0])
	for i in range(1, clean_points.size() - 1):
		var dir1 = (clean_points[i] - clean_points[i - 1]).normalized()
		var dir2 = (clean_points[i + 1] - clean_points[i]).normalized()
		if not dir1.is_equal_approx(dir2):
			corners.append(clean_points[i])
	corners.append(clean_points[clean_points.size() - 1])
	return corners

func save_changed_points(targetPos: Vector2) -> void:
	if not is_instance_valid(currentCable) or activeWayPointIndex < 0 or activeWayPointIndex >= cableWayPoints.size():
		return
	var new_global_pos = to_global(targetPos)
	var target_ID = Astar.get_closest_point(targetPos)
	cableWayPoints[activeWayPointIndex] = new_global_pos
	currentCable.waypoints[activeWayPointIndex] = new_global_pos
	if activeWayPointIndex > 0:
		var prev_IDX = activeWayPointIndex - 1
		var start_ID = Astar.get_closest_point(to_local(cableWayPoints[prev_IDX]))
		currentCable.legs[prev_IDX] = Astar.get_point_path(start_ID, target_ID)
	
	if activeWayPointIndex < cableWayPoints.size() - 1:
		var end_ID = Astar.get_closest_point(to_local(cableWayPoints[activeWayPointIndex + 1]))
		currentCable.legs[activeWayPointIndex] = Astar.get_point_path(target_ID, end_ID)
	var full_path: PackedVector2Array = []
	for i in range(currentCable.legs.size()):
		var leg = currentCable.legs[i]
		if i == 0:
			full_path.append_array(leg)
		elif leg.size() > 1:
			for j in range(1, leg.size()):
				full_path.append(leg[j])
	full_path = remove_path_loops(full_path)
	var line = _get_line2d(currentCable)
	if line:
		line.clear_points()
		for pt in full_path:
			line.add_point(currentCable.to_local(to_global(pt)))
	lastSnappedPos = targetPos

func build_legs_from_waypoints(wps: PackedVector2Array) -> Array[PackedVector2Array]:
	var new_legs: Array[PackedVector2Array] = []
	for i in range(wps.size() - 1):
		var start_ID = Astar.get_closest_point(to_local(wps[i]))
		var end_ID = Astar.get_closest_point(wps[i + 1])
		new_legs.append(Astar.get_point_path(start_ID, end_ID))
	return new_legs

func update_board_dimensions(new_board_size: Vector2i, new_board_offset: Vector2) -> void:
	boardSize = new_board_size
	boardOffset = new_board_offset
	setup_astar_grid()
