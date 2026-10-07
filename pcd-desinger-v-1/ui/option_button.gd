extends OptionButton

func _ready() -> void:
	clear()
	
	add_item("Return to main menu")
	
	item_selected.connect(_on_item_selected)

func _on_item_selected(index: int) -> void:
	if index == 1:
		if get_tree():
			get_tree().call_deferred("change_scene_to_file", "res://ui/main_menu.tscn")
		
