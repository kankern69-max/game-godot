extends Control

@onready var LineBTN = $DrawLine
@onready var FreeBTN = $DrawFree
@onready var EraseBTN = $Erase
@onready var ColorSelector = $OptionButton

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
	ColorSelector.add_item("oragne")
	ColorSelector.add_item("black")
	ColorSelector.add_item("pink")
	ColorSelector.add_item("brown")
	ColorSelector.item_selected.connect(_on_color_selected)

func _on_color_selected(index: int) -> void:
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
