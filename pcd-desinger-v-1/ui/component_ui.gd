extends Panel

var componentTile := preload("res://ui/component_tile.tscn")

@onready var panel: Panel = $"."
@onready var Vbox : VBoxContainer = $components/VBoxContainer
@onready var openCloseLabel: Label = $open_closeButton/Label
@onready var searchbar: LineEdit = $SearchBar/LineEdit
@onready var filterSort: OptionButton = $Filters/HBoxContainer/Sort
@onready var filterType: OptionButton = $Filters/HBoxContainer/Type

var _last_unlocked_count: int = -1

func _ready() -> void:
	draw_components()
	setup_type_filter()

func _process(delta):
	if Global.unlocked_components.size() != _last_unlocked_count:
		_last_unlocked_count = Global.unlocked_components.size()
		draw_components()

func setup_type_filter() -> void:
	filterType.clear()
	filterType.add_item("All types", -1)
	
	for type_key in Component.type.keys():
		var type_val: int = Component.type[type_key]
		filterType.add_item(type_key.capitalize(), type_val)

func draw_components() -> void:
	for child in Vbox.get_children():
		child.queue_free()
	
	var search_text := searchbar.text.strip_edges().to_lower()
	var selected_type_id: int = filterType.get_selected_id()
	
	var filtered_list: Array[Component] = []
	for component in Global.unlocked_components:
		if search_text != "":
			var name_match := component.component_name.to_lower().contains(search_text)
			var id_match := component.component_id.to_lower().contains(search_text)
			if not (name_match or id_match):
				continue
			
		if selected_type_id != -1 and component.component_type != selected_type_id:
			continue
			
		filtered_list.append(component)
		
	match filterSort.selected:
		0:
			filtered_list.sort_custom(func(a,b): return a.cost < b.cost)
		1:
			filtered_list.sort_custom(func(a,b): return a.component_name.naturalnocasecmp_to(b.component_name) < 0)
		2:
			filtered_list.sort_custom(func(a,b): return a.component_type < b.component_type)
		
	for component in filtered_list:
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


func _on_line_edit_text_changed(_new_text):
	draw_components()


func _on_sort_sort_selected(_index):
	draw_components()

func _on_type_type_selected(_index):
	draw_components()
