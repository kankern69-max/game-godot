extends Control
	
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Esc"):
		toggle_pause()
		
func toggle_pause() -> void:
	visible = !get_tree().paused
	get_tree().paused = !get_tree().paused
	print(get_tree().paused)


func _on_resume_pressed():
	get_tree().paused = false
	visible = false
	

func _on_button_pressed():
	get_tree().paused = false
	if get_tree():
		get_tree().call_deferred("change_scene_to_file", "res://ui/main_menu.tscn")

func _ready() -> void:  	visible = false
