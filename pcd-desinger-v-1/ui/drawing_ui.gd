extends Control

@onready var LineBTN = $DrawLine
@onready var FreeBTN = $DrawFree
@onready var EraseBTN = $Erase
@onready var ColorSelector = $OptionButton

var current_color_index: int = 0

func _ready() -> void:
	LineBTN.pressed.connect(func(): Global.toolChanged.emit("LINE"))
	FreeBTN.pressed.connect(func(): Global.toolChanged.emit("FREE"))
	EraseBTN.pressed.connect(func(): Global.toolChanged.emit("ERASE"))
	
	ColorSelector.clear()
	ColorSelector.add_item("red")
	ColorSelector.add_item("blue")
	ColorSelector.add_item("yellow")
	ColorSelector.add_item("green")
	ColorSelector.add_item("purple")
	ColorSelector.add_item("orange")
	ColorSelector.add_item("black")
	ColorSelector.add_item("pink")
	ColorSelector.add_item("brown")
	ColorSelector.item_selected.connect(_on_color_selected)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		var total_colors = ColorSelector.item_count
		
		if event.keycode == KEY_PAGEUP:
			current_color_index -= 1
			if current_color_index < 0:
				current_color_index = 0
			ColorSelector.select(current_color_index)
			_on_color_selected(current_color_index)
			
		elif event.keycode == KEY_PAGEDOWN:
			current_color_index += 1
			if current_color_index >= total_colors:
				current_color_index = total_colors -1
			ColorSelector.select(current_color_index)
			_on_color_selected(current_color_index)
		
		elif event.keycode == KEY_DELETE:
			Global.toolChanged.emit("ERASE")

func _on_color_selected(index: int) -> void:
	current_color_index = index
	match index:
		0: Global.CableColor = Color(1.0, 0.0, 0.0, 1.0)
		1: Global.CableColor = Color(0.0, 0.0, 1.0, 1.0)
		2: Global.CableColor = Color(1.0, 1.0, 0.0, 1.0)
		3: Global.CableColor = Color(0.0, 1.0, 0.0, 1.0)
		4: Global.CableColor = Color(0.625, 0.0, 0.625, 1.0)
		5: Global.CableColor = Color(0.964, 0.498, 0.0, 1.0)
		6: Global.CableColor = Color(0.0, 0.0, 0.0, 1.0)
		7: Global.CableColor = Color(1.0, 0.385, 0.991, 1.0)
		8: Global.CableColor = Color(0.361, 0.22, 0.0, 1.0)
