extends Node2D


@onready var line2d: Line2D = $Line2D

var cableID: int = 0

func setup_trace(startPosi: Vector2, endPosi: Vector2, id: int) -> void:
	cableID= id
	line2d.clear_points()
	line2d.add_point(startPosi)
	line2d.add_point(endPosi)

func update_end_point(endPosi: Vector2) -> void:
	line2d.set_point_position(1,endPosi)

func getPointStart() -> Vector2:
	return line2d.get_point_position(0)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
