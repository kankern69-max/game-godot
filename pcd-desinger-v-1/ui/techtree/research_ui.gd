extends Panel

@export var hidden_y_position: float = -700.0 
@export var visible_y_position: float = 100.0
@export var anim_duration: float = 0.4 

var larger_area1: bool = false
var larger_area2: bool = false
var larger_area3: bool = false

var is_open: bool = false
var tween: Tween

func _ready() -> void:
	$researchPanel.position.y = hidden_y_position
	$researchPanel.visible = false

func _on_research_main_button_pressed() -> void:
	is_open = !is_open
	
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween().set_parallel(false)
	
	if is_open:
		$researchPanel.visible = true
		tween.tween_property($researchPanel, "position:y", visible_y_position, anim_duration).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		tween.tween_property($researchPanel, "position:y", hidden_y_position, anim_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(func(): $researchPanel.visible = false)
