extends Node2D


@onready var line2d: Line2D = $Line2D

var cableID: int = 0

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
