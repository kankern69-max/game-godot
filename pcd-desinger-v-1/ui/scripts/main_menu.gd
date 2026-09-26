extends Control

func _on_start_pressed():
	# Speel het geluidje af
	$Klikkerdeklik.play()
	
	# Speel de fade animatie af
	$AnimationPlayer.play("fade_out")
	
	# Wacht ALLEEN tot de animatie helemaal klaar is
	await $AnimationPlayer.animation_finished
	
	# Wissel direct naar de game
	get_tree().change_scene_to_file("res://game.tscn")

func _on_credits_pressed():
	$Klikkerdeklik.play()

func _on_quit_pressed():
	$Klikkerdeklik.play()
	await $Klikkerdeklik.finished
	get_tree().quit()
