extends Node2D

@export var grid_size = Vector2i(1920, 1080)
@export var cell_size = 6

var cells = {}  # Vector2i -> Cell

const N = 1; const E = 2; const S = 4; const W = 8
var dirs = {N: Vector2i(0,-1), E: Vector2i(1,0), S: Vector2i(0,1), W: Vector2i(-1,0)}
var opposite = {N: S, E: W, S: N, W: E}

@onready var trace_layer: TileMapLayer = $WireLayer

class Cell:
	var type: String = "empty"
	var connections: int = 0
	var component_id: String = ""




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _draw():
	_draw_grid_lines()

func _draw_grid_lines():
	var color = Color(1, 1, 1, 0.15)
	for x in range(grid_size.x + 1):
		var from = Vector2(x * cell_size, 0)
		var to = Vector2(x * cell_size, grid_size.y * cell_size)
		draw_line(from, to, color, 1.0)
	for y in range(grid_size.y + 1):
		var from = Vector2(0, y * cell_size)
		var to = Vector2(grid_size.x * cell_size, y * cell_size)
		draw_line(from, to, color, 1.0)
