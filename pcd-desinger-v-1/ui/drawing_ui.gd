extends Control

@onready var LineBTN = $DrawLine
@onready var FreeBTN = $DrawFree
@onready var EraseBTN = $Erase

func _ready() -> void:
	LineBTN.pressed.connect(func(): Global.toolChanged.emit("LINE"))
	FreeBTN.pressed.connect(func(): Global.toolChanged.emit("FREE"))
	EraseBTN.pressed.connect(func(): Global.toolChanged.emit("ERASE"))
