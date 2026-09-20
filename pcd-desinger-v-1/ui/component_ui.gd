extends Panel

var componentTile := preload("res://ui/component_tile.tscn")

@onready var Vbox : VBoxContainer = $components/VBoxContainer

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
