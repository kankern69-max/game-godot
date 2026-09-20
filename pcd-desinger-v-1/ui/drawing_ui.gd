extends Control

@onready var LineBTN = $DrawLine
@onready var FreeBTN = $DrawFree
@onready var EraseBTN = $Erase
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	LineBTN.pressed.connect(func(): global.toolChanged.emit("LINE"))
	FreeBTN.pressed.connect(func(): global.toolChanged.emit("FREE"))
	EraseBTN.pressed.connect(func(): global.toolChanged.emit("ERASE"))
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
