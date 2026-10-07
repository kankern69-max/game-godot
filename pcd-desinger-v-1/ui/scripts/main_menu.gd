extends Control

func _on_start_pressed() -> void:
	if has_node("klikkerdeklik"):
		await $Klikkerdeklik.finished
		
	if get_tree():
		get_tree().call_deferred("change_scene_to_file", "res://mainSystems/game.tscn")
		
		
func _on_credits_pressed() -> void:
	if has_node("Klikkerdeklik"):
		$Klikkerdeklik.play()
		
func _on_quit_pressed() -> void:
		if has_node("Klikkerdeklik"):
			$Klikkerdeklik.play()
			get_tree().quit()
