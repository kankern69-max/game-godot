extends Node2D
var dotDistance: int = 8
const boardSize: Vector2i = Vector2i(1920,1080)
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
func _draw() -> void:
	for x in range(0, boardSize.x, dotDistance):
		for y in range(0,boardSize.y, dotDistance):
			draw_rect(Rect2(Vector2(x, y), Vector2(1, 1)), Color(0.47, 0.47, 0.47, 1.0))
	pass
