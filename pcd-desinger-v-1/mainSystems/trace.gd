extends Node2D


@onready var line2d: Line2D = $Line2D

var cableID: int = 0
var voltage: float = 0.0
var current: float = 0.0
var power: float = 0.0
var connected_source: Base_component = null


func setup_trace(startPosi: Vector2, id: int) -> void:
	cableID= id
	line2d.clear_points()
	line2d.add_point(startPosi)
	line2d.add_point(startPosi)

func addCableSegment(newPos: Vector2) -> void:
	if not newPos.is_finite():
		return
	
	var last_idx = line2d.get_point_count()-1
	if last_idx >= 0:
		line2d.set_point_position(last_idx, newPos)
	line2d.add_point(newPos)

func update_active_point(endPos: Vector2) -> void:
	if not endPos.is_finite():
		return
	var last_idx = line2d.get_point_count()-1
	if last_idx >= 0:
		line2d.set_point_position(last_idx,endPos)

func getCableCount() -> int:
	return line2d.get_point_count()

func getPointStart() -> Vector2:
	return line2d.get_point_position(0)

func getEndCable() -> Vector2:
	return line2d.get_point_position(line2d.get_point_count() - 1)

func getPenultimatePoint() -> Vector2:
	var count = line2d.get_point_count()
	if count >= 3:
		return line2d.get_point_position(count-3)
	return Vector2.INF

func removeLastCableSegment() -> void:
	var count = line2d.get_point_count()
	if count >= 3:
		line2d.remove_point(count - 2)

func checkPointExists(pos:Vector2) -> bool:
	var count = line2d.get_point_count()
	for i in range(count - 1):
		if line2d.get_point_position(i).distance_to(pos) < 1.0:
			return true
	return false

func set_cable_color(new_color: Color) -> void:
	line2d.default_color = new_color

func check_battery_connection() -> void:
	var start_Pos_global = to_global(getPointStart())
	connected_source = null
	var components = get_tree().get_nodes_in_group("circuit_components")
	for comp in components:
		if comp is Base_component:
			if comp.component_data and comp.component_data.component_type == Component.type.battery:
				var comp_pos = comp.global_position
				var grid_unit = 8.0
				var fp_size = Vector2(comp.component_data.footprint) * grid_unit
				var pin_off = Vector2(comp.component_data.pin_offset) * grid_unit
				var comp_rect = Rect2(comp_pos - pin_off, fp_size)
				comp_rect = comp_rect.grow(8.0)
				if comp_rect.has_point(start_Pos_global):
					connected_source = comp
					break
	update_cable_values()

func update_cable_values() -> void:
	if connected_source and is_instance_valid(connected_source):
		voltage = connected_source.get_voltage()
		current = connected_source.current
		power = connected_source.power
	else:
		voltage = 0.0
		current = 0.0
		power = 0.0
