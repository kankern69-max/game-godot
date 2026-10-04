extends Panel

@onready var panel: Panel = $"."
@onready var vbox: VBoxContainer = $ScrollContainer/VBoxContainer

var tile_scene: PackedScene = preload("res://ui/order_tile.tscn")

var open: bool
func _on_tab_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target_position: Vector2
		
		if open:
			target_position = position + Vector2(250, 0)
			open = false
			print("close", open)
		else:
			target_position = position - Vector2(250, 0)
			open = true
			print("open", open)
		
		var tween = create_tween()
		tween.set_trans(Tween.TransitionType.TRANS_QUAD)
		tween.set_ease(Tween.EaseType.EASE_OUT)
		tween.tween_property(panel, "position", target_position, 0.4)

func _process(delta):
	if vbox.get_child_count() != Orders.generated_orders.size():
		_update_order_ui()
		
func _update_order_ui() -> void:
	for child in vbox.get_children():
		child.queue_free()
	
	for order in Orders.generated_orders:
		var tile = tile_scene.instantiate()
		tile.order = order
		vbox.add_child(tile)
	
