extends Panel

var componentTile := preload("res://ui/component_tile.tscn")

@onready var panel: Panel = $"."
@onready var Vbox : VBoxContainer = $components/VBoxContainer
@onready var openCloseLabel: Label = $open_closeButton/Label

func _process(delta):
	if Global.unlocked_components.size() != Vbox.get_child_count():
		draw_components()
	
func draw_components() -> void:
	for child in Vbox.get_children():
		child.queue_free()
	
	for component in Global.unlocked_components:
		var tile := componentTile.instantiate()
		tile.component = component
		Vbox.add_child(tile)


func _on_open_close_button_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target_position: Vector2
		
		if openCloseLabel.text == ">":
			target_position = Vector2(1920, 20)
			openCloseLabel.text = "<"
		elif openCloseLabel.text == "<":
			target_position = Vector2(1650, 20)
			openCloseLabel.text = ">"
		else:
			push_error("Component ui open close broken!")
			return
		
		var tween = create_tween()
		tween.set_trans(Tween.TransitionType.TRANS_QUAD)
		tween.set_ease(Tween.EaseType.EASE_OUT)
		tween.tween_property(panel, "position", target_position, 0.4)
