extends Panel


func _ready() -> void:
	$researchPanel.visible = false

func _on_research_main_button_pressed() -> void:
	$researchPanel.visible = !$researchPanel.visible
	
