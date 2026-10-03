extends Panel

var larger_area1: bool = false
var larger_area2: bool = false
var larger_area3: bool = false

func _ready() -> void:
	$researchPanel.visible = false

func _on_research_main_button_pressed() -> void:
	$researchPanel.visible = !$researchPanel.visible

func _on_larger_area_1_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if larger_area1 == false:
			get_tree().call_group("pcb_board", "expand_board", 0.10)
			larger_area1 = true

func _on_larger_area_2_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if larger_area1 == true and larger_area2 == false:
			get_tree().call_group("pcb_board", "expand_board", 0.10)
			larger_area2 = true


func _on_larger_area_3_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if larger_area2 == true and larger_area3 == false:
			get_tree().call_group("pcb_board", "expand_board", 0.10)
			larger_area3 = true
