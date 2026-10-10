extends Node2D
 
const snapPoint: int = 8
const dimmedAlpha: float = 0.5
const diagonalCost: float = 1.414
const turnPenalty: float = 0.3
const directions: Array[Vector2i] = [
	Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1),
	Vector2i(-1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1)
]
enum DrawMode {FREE, LINE, ERASE, SELECT, EXTENDED_LINE}
var TraceScene: PackedScene = preload("res://mainSystems/trace.tscn")
var SavedCables: Array[Node2D] = []
var currentCable : Node2D = null
var layingCable: bool = false
var cableCounter: int = 0
var lastSnappedPos: Vector2 = Vector2.ZERO
var dotDistance: int = 8
var halfStep: float = dotDistance * 0.5
var currentMode: DrawMode = DrawMode.FREE
var lineAxisLocked: bool = false
var lockedAxis: String = ""
var startPos: Vector2 = Vector2.ZERO
var editingCable: Node2D = null
var cableWayPoints: PackedVector2Array = []
var activeWayPointIndex: int = -1
var boardSize: Vector2i = Vector2i(640, 400)
var boardOffset: Vector2 = Vector2((1920 - 640) * 0.5, (1080 - 400) * 0.5)
var Astar: DirectionalAStar = DirectionalAStar.new()
var astars: Dictionary = {}
var layers: Dictionary = {}
var layer_tweens: Dictionary = {}
var editing_legs: Array[PackedVector2Array] = []
var blocked_edges_by_layer: Dictionary = {}
var cable_waypoints_dict: Dictionary = {}
var cable_legs_dict: Dictionary = {}
var cable_corners_dict: Dictionary = {}

class DirectionalAStar extends AStar2D:
	var state_count: int = 0
	var step_length: float = 8.0
	var diagonal_cost: float = 1.414
	var turn_penalty: float = 0.0

	func _compute_cost(from_id: int, to_id: int) -> float:
		if from_id >= state_count or to_id >= state_count:
			return 0.0
		var to_heading = to_id & 7
		var cost = step_length * (diagonal_cost if (to_heading & 1) == 1 else 1.0)
		if (from_id & 7) != to_heading:
			cost += turn_penalty
		return cost

func _ready() -> void:
	add_to_group("cables_manager")
	if Global.has_signal("toolChanged"):
		Global.toolChanged.connect(GlobalToolChange)
	if Global.has_signal("cableLayerChanged"):
		Global.cableLayerChanged.connect(_on_cable_layer_changed)
	_set_working_layer(_layer_key(Global.CableColor))

func _process(_delta: float) -> void:
	for cable in SavedCables:
		if is_instance_valid(cable) and cable.has_method("check_battery_connection"):
			cable.check_battery_connection()

func setup_astar_grid() -> void:
	blocked_edges_by_layer.clear()
	for key in astars:
		_build_grid(astars[key])
	update_cable_weights()

func get_astar(key: String) -> DirectionalAStar:
	if not astars.has(key):
		var astar = DirectionalAStar.new()
		_build_grid(astar)
		astars[key] = astar
		_update_weights_for(key)
	return astars[key]

func _set_working_layer(key: String) -> void:
	Astar = get_astar(key)

func update_cable_weights() -> void:
	for key in astars:
		_update_weights_for(key)

func _cable_layer(cable: Node2D) -> String:
	var layer_key = cable.get("layer_key")
	return layer_key if layer_key != null else ""

func _build_grid(grid: DirectionalAStar) -> void:
	grid.clear()
	var columns = int(boardSize.x / dotDistance)
	var rows = int(boardSize.y / dotDistance)
	var heading_count = directions.size()
	grid.state_count = columns * rows * heading_count
	grid.step_length = dotDistance
	grid.diagonal_cost = diagonalCost
	grid.turn_penalty = turnPenalty * dotDistance
	grid.reserve_space(grid.state_count + 2)
	for x in range(columns):
		for y in range(rows):
			var cell_id = get_point_id(x, y)
			var world_position = boardOffset + Vector2(x * dotDistance + halfStep, y * dotDistance + halfStep)
			for heading in range(heading_count):
				grid.add_point(get_state_id(cell_id, heading), world_position)
	for x in range(columns):
		for y in range(rows):
			var cell_id = get_point_id(x, y)
			for heading in range(heading_count):
				for turn in range(-1, 2):
					var next_heading = posmod(heading + turn, heading_count)
					var next_cell = Vector2i(x, y) + directions[next_heading]
					if _is_cell_in_grid(next_cell, columns, rows):
						var next_id = get_state_id(get_point_id(next_cell.x, next_cell.y), next_heading)
						grid.connect_points(get_state_id(cell_id, heading), next_id, false)

func _update_weights_for(key: String) -> void:
	var grid: DirectionalAStar = astars[key]
	var columns = int(boardSize.x / dotDistance)
	var rows = int(boardSize.y / dotDistance)
	var blocked_edges: Dictionary = blocked_edges_by_layer.get(key, {})
	for edge in blocked_edges.values():
		grid.connect_points(edge.x, edge.y, false)
	blocked_edges.clear()
	blocked_edges_by_layer[key] = blocked_edges

	for x in range(columns):
		for y in range(rows):
			_set_cell_disabled(grid, Vector2i(x, y), false)

	for cable in SavedCables:
		if is_instance_valid(cable) and _cable_layer(cable) == key:
			var corners = cable_corners_dict.get(cable, null)
			if corners == null:
				corners = cable.get("corner_waypoints")
			if corners != null:
				for corner in (corners as PackedVector2Array):
					var corner_cell = pos_to_grid_coords(to_local(corner))
					for offset_x in range(-1, 2):
						for offset_y in range(-1, 2):
							var cell = Vector2i(corner_cell.x + offset_x, corner_cell.y + offset_y)
							if _is_cell_in_grid(cell, columns, rows):
								_set_cell_disabled(grid, cell, true)

			var line = _get_line2d(cable)
			if line and line.points.size() > 0:
				if line.points.size() == 1:
					var world_point = cable.to_global(line.points[0])
					_set_cell_disabled(grid, _nearest_cell(to_local(world_point)), true)
				else:
					for i in range(line.points.size() - 1):
						var segment_start = cable.to_global(line.points[i])
						var segment_end = cable.to_global(line.points[i + 1])
						var segment_length = segment_start.distance_to(segment_end)
						var steps = maxi(1, int(round(segment_length / dotDistance)))
						for s in range(steps + 1):
							var sample_point = segment_start.lerp(segment_end, float(s) / float(steps))
							_set_cell_disabled(grid, _nearest_cell(to_local(sample_point)), true)
						_block_crossing_diagonals(grid, blocked_edges, _nearest_cell(to_local(segment_start)), _nearest_cell(to_local(segment_end)))

func _block_crossing_diagonals(grid: DirectionalAStar, blocked_edges: Dictionary, from_cell: Vector2i, to_cell: Vector2i) -> void:
	var delta = to_cell - from_cell
	if delta.x == 0 or absi(delta.x) != absi(delta.y):
		return
	var columns = int(boardSize.x / dotDistance)
	var rows = int(boardSize.y / dotDistance)
	var step = Vector2i(signi(delta.x), signi(delta.y))
	for i in range(absi(delta.x)):
		var cell = from_cell + step * i
		var corner_a = Vector2i(cell.x + step.x, cell.y)
		var corner_b = Vector2i(cell.x, cell.y + step.y)
		if not _is_cell_in_grid(corner_a, columns, rows) or not _is_cell_in_grid(corner_b, columns, rows):
			continue
		_block_move(grid, blocked_edges, corner_a, corner_b)
		_block_move(grid, blocked_edges, corner_b, corner_a)

func _block_move(grid: DirectionalAStar, blocked_edges: Dictionary, from_cell: Vector2i, to_cell: Vector2i) -> void:
	var move_heading = directions.find(to_cell - from_cell)
	if move_heading == -1:
		return
	var from_cell_id = get_point_id(from_cell.x, from_cell.y)
	var to_state = get_state_id(get_point_id(to_cell.x, to_cell.y), move_heading)
	for turn in range(-1, 2):
		var from_state = get_state_id(from_cell_id, posmod(move_heading + turn, directions.size()))
		var edge_key = from_state * grid.state_count + to_state
		if blocked_edges.has(edge_key):
			continue
		grid.disconnect_points(from_state, to_state, false)
		blocked_edges[edge_key] = Vector2i(from_state, to_state)

func _set_cell_disabled(grid: DirectionalAStar, cell: Vector2i, disabled: bool) -> void:
	var cell_id = get_point_id(cell.x, cell.y)
	for heading in range(directions.size()):
		grid.set_point_disabled(get_state_id(cell_id, heading), disabled)

func _nearest_cell(local_position: Vector2) -> Vector2i:
	var cell = pos_to_grid_coords(local_position)
	var columns = int(boardSize.x / dotDistance)
	var rows = int(boardSize.y / dotDistance)
	return Vector2i(clampi(cell.x, 0, columns - 1), clampi(cell.y, 0, rows - 1))

func pos_to_grid_coords(local_position: Vector2) -> Vector2i:
	var board_position = local_position - boardOffset
	return Vector2i(int(round((board_position.x - halfStep) / dotDistance)), int(round((board_position.y - halfStep) / dotDistance)))

func get_point_id(x: int, y: int) -> int:
	var columns = int(boardSize.x / dotDistance)
	return x + y * columns

func get_state_id(cell_id: int, heading: int) -> int:
	return cell_id * directions.size() + heading

func GlobalToolChange(tool_name: String) -> void:
	if layingCable:
		if currentCable and not editingCable:
			currentCable.queue_free()
		layingCable = false
		currentCable = null
		editingCable = null
		cableWayPoints.clear()
		activeWayPointIndex = -1
	match tool_name:
		"FREE":
			currentMode = DrawMode.FREE
		"LINE":
			currentMode = DrawMode.LINE
		"ERASE":
			currentMode = DrawMode.ERASE
		"SELECT":
			currentMode = DrawMode.SELECT
		"EXTENDEDLINE":
			currentMode = DrawMode.EXTENDED_LINE

func _input(event: InputEvent) -> void:
	if currentMode == DrawMode.SELECT and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var click_position = to_local(get_global_mouse_position())
		var components = get_tree().get_nodes_in_group("circuit_components")
		for component in components:
			if component is Base_component:
				if component.contains_point(to_global(click_position)):
					if component.has_method("toggle_state"):
						component.toggle_state()
						notify_circuit_update()
						Base_component.update_all_circuits(get_tree())
						return
	if currentMode == DrawMode.ERASE:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			var mouse_position = to_local(get_global_mouse_position())
			eraseCableAt(mouse_position)
			notify_circuit_update()
			Base_component.update_all_circuits(get_tree())
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			startPos = snapToGrid(to_local(get_global_mouse_position()))
			if currentMode == DrawMode.SELECT:
				var cable_to_edit = findCableAt(startPos)
				if cable_to_edit:
					editingCable = cable_to_edit
					_set_working_layer(_cable_layer(editingCable))
					SavedCables.erase(editingCable)
					update_cable_weights()
					currentCable = editingCable
					lastSnappedPos = startPos
					layingCable = true
					setup_editing_waypoints(to_global(startPos))
					save_changed_points(startPos)
			else:
				lineAxisLocked = false
				var layer_key = _layer_key(Global.CableColor)
				_set_working_layer(layer_key)
				currentCable = TraceScene.instantiate()
				currentCable.layer_key = layer_key
				get_layer(Global.CableColor).add_child(currentCable)
				currentCable.set_cable_color(Global.CableColor)
				cableCounter += 1
				currentCable.setup_trace(startPos, cableCounter)
				lastSnappedPos = startPos
				layingCable = true
		elif layingCable:
			if is_instance_valid(currentCable):
				if editingCable != null:
					if not SavedCables.has(currentCable):
						SavedCables.append(currentCable)
					update_cable_weights()
					notify_circuit_update()
					Base_component.update_all_circuits(get_tree())
				else:
					var end_position = lastSnappedPos
					if currentCable.has_method("update_active_point"):
						currentCable.update_active_point(end_position)
					var line = _get_line2d(currentCable)
					var total_distance: float = 0.0
					if line and line.points.size() > 1:
						for i in range(line.points.size() - 1):
							total_distance += line.points[i].distance_to(line.points[i + 1])
					var cable_point_count = 0
					if currentCable.has_method("getCableCount"):
						cable_point_count = currentCable.getCableCount()
					elif currentCable.has_node("Line2D"):
						cable_point_count = (currentCable.get_node("Line2D") as Line2D).points.size()
					
					if cable_point_count > 1 and total_distance >= snapPoint:
						if not cable_waypoints_dict.has(currentCable):
							var initial_waypoints: PackedVector2Array = []
							initial_waypoints.append(currentCable.to_global(line.points[0]))
							initial_waypoints.append(currentCable.to_global(line.points[line.points.size() - 1]))
							cable_waypoints_dict[currentCable] = initial_waypoints
							cable_legs_dict[currentCable] = build_legs_from_waypoints(initial_waypoints)
							cable_corners_dict[currentCable] = extract_corner_waypoints(line.points)
						if not SavedCables.has(currentCable):
							SavedCables.append(currentCable)
						update_cable_weights()
						notify_circuit_update()
						Base_component.update_all_circuits(get_tree())
					else:
						currentCable.queue_free()
						update_cable_weights()
			layingCable = false
			currentCable = null
			editingCable = null
			cableWayPoints.clear()
			activeWayPointIndex = -1
	elif event is InputEventMouseMotion and layingCable:
		var mouse_position = clampToBoard(to_local(get_global_mouse_position()))
		var target_position = snapToGrid(mouse_position)
		if target_position == lastSnappedPos and (currentMode == DrawMode.FREE or currentMode == DrawMode.SELECT or currentMode == DrawMode.EXTENDED_LINE):
			return
		if currentMode == DrawMode.SELECT and is_instance_valid(currentCable):
			save_changed_points(target_position)
		elif currentMode == DrawMode.FREE:
			var path = remove_collinear_points(find_path(startPos, target_position))
			if path.is_empty():
				return

			var line = _get_line2d(currentCable)
			if line:
				line.clear_points()
				for point in path:
					line.add_point(currentCable.to_local(to_global(point)))

			var global_points: PackedVector2Array = []
			for point in path:
				global_points.append(to_global(point))
			var corners = extract_corner_waypoints(global_points)
			cable_corners_dict[currentCable] = corners
			currentCable.set("corner_waypoints", corners)

			var initial_waypoints: PackedVector2Array = []
			initial_waypoints.append(to_global(path[0]))
			initial_waypoints.append(to_global(path[path.size() - 1]))
			cable_waypoints_dict[currentCable] = initial_waypoints

			lastSnappedPos = target_position
		elif currentMode == DrawMode.EXTENDED_LINE:
			var path = generate_extendedLine_path(startPos, target_position)
			path = clean_astar_path(path)
			var line = _get_line2d(currentCable)
			if line:
				line.clear_points()
				for point in path:
					line.add_point(currentCable.to_local(point))
			if currentCable.has_method("update_active_point") and path.size() > 0:
				currentCable.update_active_point(currentCable.to_local(path[path.size() - 1]))
			lastSnappedPos = target_position
		elif currentMode == DrawMode.LINE:
			if not lineAxisLocked:
				var initial_offset = mouse_position - startPos
				if initial_offset.length() >= snapPoint:
					lineAxisLocked = true
					var abs_x = absf(initial_offset.x)
					var abs_y = absf(initial_offset.y)
					var larger = maxf(abs_x, abs_y)
					var smaller = minf(abs_x, abs_y)
					if smaller > larger * 0.414:
						lockedAxis = "d"
					elif abs_x > abs_y:
						lockedAxis = "x"
					else:
						lockedAxis = "y"
			if lineAxisLocked:
				if lockedAxis == "x":
					mouse_position.y = startPos.y
				elif lockedAxis == "y":
					mouse_position.x = startPos.x
				elif lockedAxis == "d":
					var initial_offset = mouse_position - startPos
					var diagonal_length = round((absf(initial_offset.x) + absf(initial_offset.y)) * 0.5 / snapPoint) * snapPoint
					mouse_position.x = startPos.x + (signf(initial_offset.x) * diagonal_length)
					mouse_position.y = startPos.y + (signf(initial_offset.y) * diagonal_length)
			var offset = mouse_position - lastSnappedPos
			while absf(offset.x) >= snapPoint or absf(offset.y) >= snapPoint:
				var step_x: float = 0.0
				var step_y: float = 0.0
				if lockedAxis == "d":
					step_x = signf(offset.x) * snapPoint
					step_y = signf(offset.y) * snapPoint
				else:
					if absf(offset.x) >= snapPoint:
						step_x = signf(offset.x) * snapPoint
					if absf(offset.y) >= snapPoint:
						step_y = signf(offset.y) * snapPoint
				var step = Vector2(step_x, step_y)
				if step == Vector2.ZERO:
					break
				var next_position = clampToBoard(lastSnappedPos + step)
				if next_position == lastSnappedPos:
					break
				if currentCable.has_method("getPenultimatePoint") and currentCable.getPenultimatePoint() == to_global(next_position):
					currentCable.removeLastCableSegment()
					lastSnappedPos = next_position
				elif currentCable.has_method("checkPointExists") and currentCable.checkPointExists(to_global(next_position)):
					break
				else:
					lastSnappedPos = next_position
					currentCable.addCableSegment(lastSnappedPos)
				offset = mouse_position - lastSnappedPos
			if currentCable.has_method("update_active_point"):
				currentCable.update_active_point(lastSnappedPos)

func find_path(from_position: Vector2, to_position: Vector2, incoming_direction: int = -1) -> PackedVector2Array:
	var columns = int(boardSize.x / dotDistance)
	var rows = int(boardSize.y / dotDistance)
	var start_cell = pos_to_grid_coords(from_position)
	var end_cell = pos_to_grid_coords(to_position)
	if not _is_cell_in_grid(start_cell, columns, rows) or not _is_cell_in_grid(end_cell, columns, rows):
		return PackedVector2Array()
	var start_cell_id = get_point_id(start_cell.x, start_cell.y)
	var end_cell_id = get_point_id(end_cell.x, end_cell.y)
	if Astar.is_point_disabled(get_state_id(end_cell_id, 0)):
		return PackedVector2Array()
	if start_cell == end_cell:
		return PackedVector2Array([_cell_to_position(start_cell)])

	var start_node = Astar.state_count
	var end_node = start_node + 1
	var start_was_disabled = Astar.is_point_disabled(get_state_id(start_cell_id, 0))
	if start_was_disabled:
		_set_cell_disabled(Astar, start_cell, false)
	Astar.add_point(start_node, _cell_to_position(start_cell))
	Astar.add_point(end_node, _cell_to_position(end_cell))
	for heading in range(directions.size()):
		if incoming_direction == -1 or heading == incoming_direction:
			Astar.connect_points(start_node, get_state_id(start_cell_id, heading), false)
		Astar.connect_points(get_state_id(end_cell_id, heading), end_node, false)

	var raw_path = Astar.get_point_path(start_node, end_node)

	Astar.remove_point(start_node)
	Astar.remove_point(end_node)
	if start_was_disabled:
		_set_cell_disabled(Astar, start_cell, true)

	var path = PackedVector2Array()
	for point in raw_path:
		if path.is_empty() or not path[path.size() - 1].is_equal_approx(point):
			path.append(point)
	return path

func _is_cell_in_grid(cell: Vector2i, columns: int, rows: int) -> bool:
	return cell.x >= 0 and cell.x < columns and cell.y >= 0 and cell.y < rows

func _cell_to_position(cell: Vector2i) -> Vector2:
	return boardOffset + Vector2(cell.x * dotDistance + halfStep, cell.y * dotDistance + halfStep)

func get_end_direction(path: PackedVector2Array, fallback_direction: int) -> int:
	if path.size() < 2:
		return fallback_direction
	var last_step = path[path.size() - 1] - path[path.size() - 2]
	var direction = directions.find(Vector2i(last_step.sign()))
	return direction if direction != -1 else fallback_direction

func get_start_direction(path: PackedVector2Array) -> int:
	if path.size() < 2:
		return -1
	return directions.find(Vector2i((path[1] - path[0]).sign()))

func _is_turn_allowed(from_direction: int, to_direction: int) -> bool:
	if from_direction == -1 or to_direction == -1:
		return true
	var difference = posmod(from_direction - to_direction, directions.size())
	return difference <= 1 or difference >= directions.size() - 1

func remove_collinear_points(path: PackedVector2Array) -> PackedVector2Array:
	if path.size() <= 2:
		return path
	var result = PackedVector2Array()
	result.append(path[0])
	for i in range(1, path.size() - 1):
		var direction_before = (path[i] - path[i - 1]).normalized()
		var direction_after = (path[i + 1] - path[i]).normalized()
		if not direction_before.is_equal_approx(direction_after):
			result.append(path[i])
	result.append(path[path.size() - 1])
	return result

func clean_astar_path(path: PackedVector2Array) -> PackedVector2Array:
	if path.size() <= 2:
		return path

	var cleaned: PackedVector2Array = []
	var visited_indices: Dictionary = {}

	for point in path:
		var snapped_point = snapToGrid(point)
		var key = Vector2i(round(snapped_point.x), round(snapped_point.y))
		if visited_indices.has(key):
			var index: int = visited_indices[key]
			cleaned.resize(index + 1)
			visited_indices.clear()
			for i in range(cleaned.size()):
				var cleaned_key = Vector2i(round(cleaned[i].x), round(cleaned[i].y))
				visited_indices[cleaned_key] = i
		else:
			visited_indices[key] = cleaned.size()
			cleaned.append(snapped_point)

	return remove_collinear_points(cleaned)

func _get_line2d(cable: Node2D) -> Line2D:
	if cable is Line2D:
		return cable as Line2D
	elif cable.has_node("Line2D"):
		return cable.get_node("Line2D") as Line2D
	return null

func generate_extendedLine_path(from_position: Vector2, to_position: Vector2) -> PackedVector2Array:
	var raw_path: PackedVector2Array = []
	raw_path.append(from_position)
	var delta = to_position - from_position
	if abs(delta.y) >= abs(delta.x):
		var step_y: float = sign(delta.y) * dotDistance
		if step_y == 0:
			return raw_path
		var total_rows = int(round(abs(delta.y) / dotDistance))
		if total_rows < 3:
			raw_path.append(clampToBoard(Vector2(from_position.x, to_position.y)))
			return raw_path
		var current_point = from_position
		var extent = dotDistance * 2
		current_point.y += step_y
		raw_path.append(clampToBoard(current_point))
		var direction = 1
		current_point.x += extent * direction
		raw_path.append(clampToBoard(current_point))
		var rows_done = 1
		while rows_done < total_rows - 2:
			current_point.y += step_y
			raw_path.append(clampToBoard(current_point))
			direction *= -1
			current_point.x = from_position.x + (extent * direction)
			raw_path.append(clampToBoard(current_point))
			rows_done += 1
		current_point.y += step_y
		raw_path.append(clampToBoard(current_point))
		current_point.x = from_position.x
		raw_path.append(clampToBoard(current_point))
		current_point.y = to_position.y
		raw_path.append(clampToBoard(current_point))
	else:
		var step_x: float = sign(delta.x) * dotDistance
		if step_x == 0:
			return raw_path
		var total_columns = int(round(abs(delta.x) / dotDistance))
		if total_columns < 3:
			raw_path.append(clampToBoard(Vector2(to_position.x, from_position.y)))
			return raw_path
		var current_point = from_position
		var extent = dotDistance * 2
		current_point.x += step_x
		raw_path.append(clampToBoard(current_point))
		var direction = 1
		current_point.y += extent * direction
		raw_path.append(clampToBoard(current_point))
		var columns_done = 1
		while columns_done < total_columns - 2:
			current_point.x += step_x
			raw_path.append(clampToBoard(current_point))
			direction *= -1
			current_point.y = from_position.y + (extent * direction)
			raw_path.append(clampToBoard(current_point))
			columns_done += 1
		current_point.x += step_x
		raw_path.append(clampToBoard(current_point))
		current_point.y = from_position.y
		raw_path.append(clampToBoard(current_point))
		current_point.x = to_position.x
		raw_path.append(clampToBoard(current_point))
	var full_grid_path: PackedVector2Array = []
	for i in range(raw_path.size() - 1):
		var segment_start = raw_path[i]
		var segment_end = raw_path[i + 1]
		var segment_length = segment_start.distance_to(segment_end)
		var steps = int(round(segment_length / dotDistance))
		for s in range(steps):
			var interpolated = segment_start.lerp(segment_end, float(s) / max(steps, 1))
			full_grid_path.append(snapToGrid(interpolated))
	if raw_path.size() > 0:
		full_grid_path.append(snapToGrid(raw_path[raw_path.size() - 1]))
	return full_grid_path

func findCableAt(target_position: Vector2) -> Node2D:
	var global_target = to_global(snapToGrid(target_position))
	var active_key = _layer_key(Global.CableColor)
	for cable in SavedCables:
		if is_instance_valid(cable) and _cable_layer(cable) == active_key:
			var line = _get_line2d(cable)
			if line and line.points.size() > 0:
				if line.points.size() == 1:
					if cable.to_global(line.points[0]).distance_to(global_target) < 12.0:
						return cable
				else:
					for i in range(line.points.size() - 1):
						var segment_start = cable.to_global(line.points[i])
						var segment_end = cable.to_global(line.points[i + 1])
						var closest_point = Geometry2D.get_closest_point_to_segment(global_target, segment_start, segment_end)
						if closest_point.distance_to(global_target) < 12.0:
							return cable
			elif cable.position.distance_to(target_position) < 24.0:
				return cable
	return null

func eraseCableAt(target_position: Vector2) -> void:
	var global_target = to_global(snapToGrid(target_position))
	for i in range(SavedCables.size() - 1, -1, -1):
		var cable = SavedCables[i]
		if is_instance_valid(cable) and _cable_layer(cable) == _layer_key(Global.CableColor):
			var line = _get_line2d(cable)
			var is_match = false
			if line and line.points.size() > 0:
				if line.points.size() == 1:
					if cable.to_global(line.points[0]).distance_to(global_target) < 12.0:
						is_match = true
				else:
					for j in range(line.points.size() - 1):
						var segment_start = cable.to_global(line.points[j])
						var segment_end = cable.to_global(line.points[j + 1])
						var closest_point = Geometry2D.get_closest_point_to_segment(global_target, segment_start, segment_end)
						if closest_point.distance_to(global_target) < 12.0:
							is_match = true
							break
			elif cable.position.distance_to(target_position) < 24.0:
				is_match = true
			if is_match:
				cable_waypoints_dict.erase(cable)
				cable_legs_dict.erase(cable)
				cable_corners_dict.erase(cable)
				cable.queue_free()
				SavedCables.remove_at(i)
				update_cable_weights()
				return

func snapToGrid(point: Vector2) -> Vector2:
	var board_position = point - boardOffset
	var clamped_x = clampf(board_position.x, 0, boardSize.x)
	var clamped_y = clampf(board_position.y, 0, boardSize.y)
	var snapped_x = floorf(clamped_x / dotDistance) * dotDistance + halfStep
	var snapped_y = floorf(clamped_y / dotDistance) * dotDistance + halfStep
	snapped_x = clampf(snapped_x, halfStep, boardSize.x - halfStep)
	snapped_y = clampf(snapped_y, halfStep, boardSize.y - halfStep)
	return boardOffset + Vector2(snapped_x, snapped_y)

func clampToBoard(point: Vector2) -> Vector2:
	var board_position = point - boardOffset
	var clamped_x = clampf(board_position.x, halfStep, boardSize.x - halfStep)
	var clamped_y = clampf(board_position.y, halfStep, boardSize.y - halfStep)
	return boardOffset + Vector2(clamped_x, clamped_y)

func notify_circuit_update() -> void:
	get_tree().call_group("circuit_components", "rebuild_connections")
	_reset_circuit_power()
	get_tree().call_group("circuit_components", "update_simulation")

	for component in get_tree().get_nodes_in_group("circuit_components"):
		if is_instance_valid(component) and component.get("is_powered") == true:
			AchievementManager.add_progress("first_circuit", 1)
			break

func _reset_circuit_power() -> void:
	for cable in get_tree().get_nodes_in_group("cables"):
		if is_instance_valid(cable) and cable.has_method("set_powered"):
			cable.set_powered(false)
	for component in get_tree().get_nodes_in_group("circuit_components"):
		if is_instance_valid(component):
			component.is_powered = false
			component.voltage = 0.0
			component.current = 0.0

func setup_editing_waypoints(global_click_position: Vector2) -> void:
	cableWayPoints.clear()
	editing_legs.clear()
	activeWayPointIndex = -1
	if not is_instance_valid(editingCable):
		return

	if cable_waypoints_dict.has(editingCable) and (cable_waypoints_dict[editingCable] as PackedVector2Array).size() >= 2:
		cableWayPoints = (cable_waypoints_dict[editingCable] as PackedVector2Array).duplicate()
	else:
		var line = _get_line2d(editingCable)
		if not line or line.points.size() < 2:
			return
		cableWayPoints.append(editingCable.to_global(line.points[0]))
		cableWayPoints.append(editingCable.to_global(line.points[line.points.size() - 1]))
		cable_waypoints_dict[editingCable] = cableWayPoints.duplicate()

	var stored_legs: Array[PackedVector2Array] = []
	if cable_legs_dict.has(editingCable):
		stored_legs.assign(cable_legs_dict[editingCable] as Array)
	else:
		var built = build_legs_from_waypoints(cableWayPoints)
		stored_legs = built
		cable_legs_dict[editingCable] = stored_legs.duplicate()

	var legs_match = stored_legs.size() == cableWayPoints.size() - 1
	for leg in stored_legs:
		if leg.is_empty():
			legs_match = false

	var closest_index = -1
	var closest_distance = 16.0
	for i in range(cableWayPoints.size()):
		var distance = cableWayPoints[i].distance_to(global_click_position)
		if distance < closest_distance:
			closest_distance = distance
			closest_index = i

	if closest_index > 0 and closest_index < cableWayPoints.size() - 1:
		activeWayPointIndex = closest_index
	else:
		var closest_segment_index = 0
		var closest_segment_distance = INF
		for i in range(cableWayPoints.size() - 1):
			var segment_start = cableWayPoints[i]
			var segment_end = cableWayPoints[i + 1]
			var closest_point = Geometry2D.get_closest_point_to_segment(global_click_position, segment_start, segment_end)
			var distance = closest_point.distance_to(global_click_position)
			if distance < closest_segment_distance:
				closest_segment_distance = distance
				closest_segment_index = i
		activeWayPointIndex = closest_segment_index + 1
		cableWayPoints.insert(activeWayPointIndex, global_click_position)
		if legs_match and closest_segment_index < stored_legs.size():
			stored_legs.insert(activeWayPointIndex, stored_legs[closest_segment_index])

	if legs_match and stored_legs.size() == cableWayPoints.size() - 1:
		editing_legs = stored_legs
	else:
		editing_legs = build_legs_from_waypoints(cableWayPoints)
	if editing_legs.is_empty():
		activeWayPointIndex = -1

func extract_corner_waypoints(points: PackedVector2Array) -> PackedVector2Array:
	if points.size() <= 2:
		return points.duplicate()
	var unique_points: PackedVector2Array = []
	unique_points.append(points[0])
	for i in range(1, points.size()):
		if points[i].distance_squared_to(unique_points[unique_points.size() - 1]) > 0.1:
			unique_points.append(points[i])
	if unique_points.size() <= 2:
		return unique_points
	var corners: PackedVector2Array = []
	corners.append(unique_points[0])
	for i in range(1, unique_points.size() - 1):
		var direction_before = (unique_points[i] - unique_points[i - 1]).normalized()
		var direction_after = (unique_points[i + 1] - unique_points[i]).normalized()
		if not direction_before.is_equal_approx(direction_after):
			corners.append(unique_points[i])
	corners.append(unique_points[unique_points.size() - 1])
	return corners

func save_changed_points(target_position: Vector2) -> void:
	if not is_instance_valid(currentCable) or activeWayPointIndex < 0 or activeWayPointIndex >= cableWayPoints.size():
		return
	if editing_legs.size() != cableWayPoints.size() - 1:
		return

	var new_waypoints = cableWayPoints.duplicate()
	new_waypoints[activeWayPointIndex] = to_global(target_position)

	var legs: Array[PackedVector2Array] = []
	legs.assign(editing_legs)

	var left_leg_idx = activeWayPointIndex - 1
	if left_leg_idx >= 0:
		var incoming_heading = -1
		if left_leg_idx > 0:
			incoming_heading = get_end_direction(legs[left_leg_idx - 1], -1)
		var leg = find_path(to_local(new_waypoints[left_leg_idx]), to_local(new_waypoints[left_leg_idx + 1]), incoming_heading)
		if leg.is_empty() and incoming_heading != -1:
			leg = find_path(to_local(new_waypoints[left_leg_idx]), to_local(new_waypoints[left_leg_idx + 1]), -1)
		if leg.is_empty():
			return
		legs[left_leg_idx] = remove_collinear_points(leg)

	var right_leg_idx = activeWayPointIndex
	if right_leg_idx < legs.size():
		var incoming_heading = -1
		if right_leg_idx > 0:
			incoming_heading = get_end_direction(legs[right_leg_idx - 1], -1)
		var leg = find_path(to_local(new_waypoints[right_leg_idx]), to_local(new_waypoints[right_leg_idx + 1]), incoming_heading)
		if leg.is_empty() and incoming_heading != -1:
			leg = find_path(to_local(new_waypoints[right_leg_idx]), to_local(new_waypoints[right_leg_idx + 1]), -1)
		if leg.is_empty():
			return
		legs[right_leg_idx] = remove_collinear_points(leg)

	cableWayPoints = new_waypoints
	editing_legs = legs.duplicate()

	cable_waypoints_dict[currentCable] = cableWayPoints.duplicate()
	cable_legs_dict[currentCable] = legs.duplicate()

	var full_path: PackedVector2Array = []
	for i in range(legs.size()):
		var leg = legs[i]
		if i == 0:
			full_path.append_array(leg)
		elif leg.size() > 1:
			for j in range(1, leg.size()):
				full_path.append(leg[j])

	full_path = remove_collinear_points(full_path)

	var global_points: PackedVector2Array = []
	for point in full_path:
		global_points.append(to_global(point))
	var corners = extract_corner_waypoints(global_points)
	cable_corners_dict[currentCable] = corners
	currentCable.set("corner_waypoints", corners)

	var line = _get_line2d(currentCable)
	if line:
		line.clear_points()
		for point in full_path:
			line.add_point(currentCable.to_local(to_global(point)))
	lastSnappedPos = target_position

func build_legs_from_waypoints(waypoints: PackedVector2Array) -> Array[PackedVector2Array]:
	var legs: Array[PackedVector2Array] = []
	var heading = -1
	for i in range(waypoints.size() - 1):
		var from_position = to_local(waypoints[i])
		var to_position = to_local(waypoints[i + 1])
		var leg = find_path(from_position, to_position, heading)
		if leg.is_empty() and heading != -1:
			leg = find_path(from_position, to_position, -1)
		if leg.is_empty():
			legs.clear()
			return legs
		heading = get_end_direction(leg, heading)
		legs.append(remove_collinear_points(leg))
	return legs

func update_board_dimensions(new_board_size: Vector2i, new_board_offset: Vector2) -> void:
	boardSize = new_board_size
	boardOffset = new_board_offset
	setup_astar_grid()

func _layer_key(color: Color) -> String:
	return color.to_html(false)

func get_layer(color: Color) -> Node2D:
	var key = _layer_key(color)
	if not layers.has(key):
		var layer = Node2D.new()
		layer.name = "Layer_" + key
		add_child(layer)
		layers[key] = layer
		layer.modulate.a = 1.0 if key == _layer_key(Global.CableColor) else dimmedAlpha
	return layers[key]

func _on_cable_layer_changed(active_color: Color) -> void:
	var active_key = _layer_key(active_color)
	for key in layers:
		var layer: Node2D = layers[key]
		var target_alpha: float = 1.0 if key == active_key else dimmedAlpha
		if layer_tweens.has(key) and layer_tweens[key]:
			layer_tweens[key].kill()
		var tween = create_tween()
		tween.tween_property(layer, "modulate:a", target_alpha, 0.12)
		layer_tweens[key] = tween
