extends Control

func _on_start_pressed() -> void:
	$Klikkerdeklik.play()
	await$Klikkerdeklik.finished
	get_tree().change_scene_to_file("res://mainSystems/game.tscn")

func _on_credits_pressed() -> void:
	$Klikkerdeklik.play()

func _on_quit_pressed() -> void:
	$Klikkerdeklik.play()
	get_tree().quit()
