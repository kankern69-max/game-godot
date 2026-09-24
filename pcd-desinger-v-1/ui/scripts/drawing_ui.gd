extends Control

@onready var colorUI: Panel = $color
@onready var colorLabel: Label = $color/Label

var colors: Array[Color] = [
	Color(1.0, 0.0, 0.0, 1.0),      # red
	Color(0.0, 0.0, 1.0, 1.0),      # blue
	Color(1.0, 1.0, 0.0, 1.0),      # yellow
	Color(0.0, 1.0, 0.0, 1.0),      # green
	Color(0.625, 0.0, 0.625, 1.0),  # purple
	Color(0.964, 0.498, 0.0, 1.0),  # orange
	Color(0.0, 0.0, 0.0, 1.0),      # black
	Color(1.0, 0.385, 0.991, 1.0),  # pink
	Color(0.361, 0.22, 0.0, 1.0),   # brown
]

var current_color_index: int = 0

func _ready() -> void:
	_on_color_selected(0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_PAGEUP:
			current_color_index = max(current_color_index - 1, 0)
			_on_color_selected(current_color_index)
			
		elif event.keycode == KEY_PAGEDOWN:
			current_color_index = min(current_color_index + 1, colors.size() - 1)
			_on_color_selected(current_color_index)
		
		elif event.keycode == KEY_DELETE:
			Global.toolChanged.emit("ERASE")

func _on_color_selected(index: int) -> void:
	current_color_index = index
	var stylebox := colorUI.get_theme_stylebox("panel") as StyleBoxFlat
	stylebox.bg_color = colors[current_color_index]
	colorUI.add_theme_stylebox_override("panel", stylebox)
	colorLabel.text = "layer: %s" % current_color_index
	Global.CableColor = colors[current_color_index]


func _on_line_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Global.toolChanged.emit("LINE")


func _on_free_draw_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Global.toolChanged.emit("FREE")

func _on_move_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Global.toolChanged.emit("SELECT")

func _on_erase_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Global.toolChanged.emit("ERASE")

func _on_line2_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Global.toolChanged.emit("EXTENDEDLINE")
