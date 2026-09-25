extends Node2D

const dotDistance: int = 8
const boardSize: Vector2i = Vector2i(640, 400)
const boardOffset: Vector2 = Vector2((1920 - 640) * 0.5, (1080 - 400) * 0.5)
const halfStep: float = dotDistance * 0.5

@export var component_scene: PackedScene = preload("res://components/component_base.tscn")

var placing: bool = false
var erasing: bool = false
var ghost: Base_component = null
var occupied: Dictionary = {}
var placed_components: Array[Base_component] = []

func _ready() -> void:
	Global.toolChanged.connect(_on_tool_changed)

func _on_tool_changed(toolName: String) -> void:
	erasing = toolName == "ERASE"
	if toolName == "PLACE" and Global.selected_component:
		_start_placing()
	else:
		_cancel_placing()

func _start_placing() -> void:
	_cancel_placing()
	ghost = component_scene.instantiate()
	ghost.component_data = Global.selected_component
	ghost.modulate.a = 0.5
	add_child(ghost)
	placing = true

func _cancel_placing() -> void:
	if ghost:
		ghost.queue_free()
		ghost = null
	placing = false
	 

func _input(event: InputEvent) -> void:
	if erasing:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mousePos = to_local(get_global_mouse_position())
			_erase_component_at(mousePos)
		return
	
	if not placing:
		return
	
	if event is InputEventMouseMotion:
		_update_ghost_position()
	
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_try_place()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			Global.selected_component = null
			Global.toolChanged.emit("FREE")

func _update_ghost_position() -> void:
	var mousePos = to_local(get_global_mouse_position())
	var pinSize = ghost.get_pin_footprint()
	var gridPos = _snap_to_grid(mousePos, pinSize)
	ghost.position = gridPos
	var cell = _to_cell(gridPos)
	if _cell_free(cell, pinSize):
		ghost.modulate = Color(1,1,1, 0.5)
	else:
		ghost.modulate = Color(1, 0.3, 0.3, 0.5)

func _try_place() -> void:
	var cell = _to_cell(ghost.position)
	var pinSize = ghost.get_pin_footprint()
	if not _cell_free(cell, pinSize):
		return
	
	var comp: Base_component = component_scene.instantiate()
	comp.component_data = Global.selected_component
	comp.position = ghost.position
	
	self.add_child(comp)
	
	placed_components.append(comp)
	_mark_occupied(cell, comp.get_pin_footprint(), comp)
	
	Global.componentPlaced.emit()
	
func remove_component(comp: Base_component) -> void:
	if comp not in placed_components:
		return
	for cell in occupied.keys().duplicate():
		if occupied[cell] == comp:
			occupied.erase(cell)
	placed_components.erase(comp)
	comp.queue_free()
	Global.componentPlaced.emit()

func _erase_component_at(pos: Vector2) -> void:
	var localPos = pos - boardOffset
	var clamped_x = clampf(localPos.x, 0, boardSize.x)
	var clamped_y = clampf(localPos.y, 0, boardSize.y)
	var cell := Vector2i(int(clamped_x / dotDistance), int(clamped_y / dotDistance))
	if occupied.has(cell):
		remove_component(occupied[cell])

func _snap_to_grid(pos: Vector2, footprint: Vector2i) -> Vector2:
	var localPos = pos - boardOffset
	var clamped_x = clampf(localPos.x, 0, boardSize.x)
	var clamped_y = clampf(localPos.y, 0, boardSize.y)
	var snapped_x = floor(clamped_x / dotDistance) * dotDistance + halfStep
	var snapped_y = floor(clamped_y / dotDistance) * dotDistance + halfStep -0.5
	return boardOffset + Vector2(snapped_x, snapped_y)

func _to_cell(worldPos: Vector2) -> Vector2i:
	var localPos = worldPos - boardOffset
	return Vector2i(int(localPos.x / dotDistance), int(localPos.y / dotDistance))

func _footprint_cells(originCell: Vector2i, footprint: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var cellSpan := Vector2i(max(1, int(ceil(float(footprint.x) / dotDistance))), max(1, int(ceil(float(footprint.x) / dotDistance))))
	for x in range(cellSpan.x):
		for y in range(cellSpan.y):
			cells.append(originCell + Vector2i(x,y))
	return cells

func _cell_free(originCell: Vector2i, footprint: Vector2i) -> bool:
	for cell in _footprint_cells(originCell, footprint):
		if occupied.has(cell):
			return false
	return true

func _mark_occupied(originCell: Vector2i, footprint: Vector2i, comp: Base_component) -> void:
	for cell in _footprint_cells(originCell, footprint):
		occupied[cell] = comp
