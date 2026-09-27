extends Node2D

var dotDistance: int = 8
const windowSize: Vector2i = Vector2i(1920, 1080)
const boardSize: Vector2i = Vector2i(640, 400)
const boardOffset: Vector2 = Vector2((1920-640) * 0.5, (1080-400) * 0.5)

func _ready() -> void:
	if has_node("FadeOverlay"):
		var overlay = $FadeOverlay
		
		# Reset de positie en grootte strak op het scherm
		overlay.position = Vector2.ZERO
		overlay.size = Vector2(1920, 1080)
		overlay.modulate.a = 1.0
		
		var tween = create_tween().set_parallel(true)
		
		# 1. Fade-out naar transparant
		tween.tween_property(overlay, "modulate:a", 0.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		
		# 2. Schuif hem ver genoeg omhoog (-600) zodat de rand snel buiten beeld schuift
		tween.tween_property(overlay, "position:y", -600.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
		await tween.finished
		overlay.queue_free()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_F11 or event.keycode == KEY_F11:
			toggle_fullscreen()

func toggle_fullscreen() -> void:
	var current_mode = DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN or current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, Vector2(windowSize)), Color(0.667, 0.667, 0.667, 1.0))
	var boardRect := Rect2(boardOffset, Vector2(boardSize))
	draw_rect(boardRect, Color(0.0, 0.592, 0.0, 1.0))
	
	for x in range(0, boardSize.x + 1, dotDistance):
		var start_p := boardOffset + Vector2(x, 0)
		var end_p := boardOffset + Vector2(x, boardSize.y)
		draw_line(start_p, end_p, Color(0.0, 0.334, 0.0, 1.0), 1.0)
		
	for y in range(0, boardSize.y + 1, dotDistance):
		var start_p := boardOffset + Vector2(0, y)
		var end_p := boardOffset + Vector2(boardSize.x, y)
		draw_line(start_p, end_p, Color(0.0, 0.334, 0.0, 1.0), 1.0)
		
	var halfStep = dotDistance * 0.5
	for x in range(0, boardSize.x, dotDistance):
		for y in range(0, boardSize.y, dotDistance):
			var dot_pos := boardOffset + Vector2(x + halfStep - 0.5, y + halfStep - 0.5)
			draw_rect(Rect2(dot_pos, Vector2(1, 1)), Color(0.073, 0.073, 0.073, 1.0))
