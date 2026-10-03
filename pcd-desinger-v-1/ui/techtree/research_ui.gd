extends Panel

var larger_area1: bool = false
var larger_area2: bool = false
var larger_area3: bool = false

func _ready() -> void:
	$researchPanel.visible = false

func _on_research_main_button_pressed() -> void:
	$researchPanel.visible = !$researchPanel.visible
