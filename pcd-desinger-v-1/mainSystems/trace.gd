extends Node2D

@onready var line2d: Line2D = $Line2D

var cableID: int = 0
var voltage: float = 0.0
var current: float = 0.0
var power: float = 0.0

func setup_trace(startPosi: Vector2, id: int) -> void:
	add_to_group("cables")
	cableID = id
	line2d.clear_points()
	line2d.add_point(startPosi)
	line2d.add_point(startPosi)

func addCableSegment(newPos: Vector2) -> void:
	if not newPos.is_finite():
		return
	var last_idx = line2d.get_point_count() - 1
	if last_idx >= 0:
		line2d.set_point_position(last_idx, newPos)
	line2d.add_point(newPos)

func update_active_point(endPos: Vector2) -> void:
	if not endPos.is_finite():
		return
	var last_idx = line2d.get_point_count() - 1
	if last_idx >= 0:
		line2d.set_point_position(last_idx, endPos)

func getCableCount() -> int:
	return line2d.get_point_count()

func getPointStart() -> Vector2:
	if line2d.get_point_count() > 0:
		return line2d.to_global(line2d.get_point_position(0))
	return global_position

func getEndCable() -> Vector2:
	var count = line2d.get_point_count()
	if count > 0:
		return line2d.to_global(line2d.get_point_position(count - 1))
	return global_position

func get_all_global_points() -> Array[Vector2]:
	var pts: Array[Vector2] = []
	for p in line2d.points:
		pts.append(line2d.to_global(p))
	return pts

func getPenultimatePoint() -> Vector2:
	var count = line2d.get_point_count()
	if count >= 3:
		return line2d.to_global(line2d.get_point_position(count - 3))
	return Vector2.INF

func removeLastCableSegment() -> void:
	var count = line2d.get_point_count()
	if count >= 3:
		line2d.remove_point(count - 2)

func checkPointExists(pos: Vector2) -> bool:
	var count = line2d.get_point_count()
	for i in range(count - 1):
		if line2d.to_global(line2d.get_point_position(i)).distance_to(pos) < 1.0:
			return true
	return false

func set_cable_color(new_color: Color) -> void:
	line2d.default_color = new_color

func update_visuals() -> void:
	if voltage > 0.0:
		line2d.default_color = Color(1.0, 0.85, 0.2) 
	else:
		line2d.default_color = Color(0.35, 0.35, 0.35) 

func set_powered(powered: bool) -> void:
	voltage = 5.0 if powered else 0.0
	current = 1.0 if powered else 0.0
	power = voltage * current
	update_visuals()
