extends Control

func _on_start_pressed():
	$Klikkerdeklik.play()
	await $Klikkerdeklik.finished
	get_tree().change_scene_to_file("res://game.tscn")

func _on_credits_pressed():
	$Klikkerdeklik.play()


func _on_quit_pressed():
	$Klikkerdeklik.play()
	await $Klikkerdeklik.finished
	get_tree().quit()
