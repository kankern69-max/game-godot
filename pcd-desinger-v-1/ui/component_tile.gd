extends Panel

@onready var img: TextureRect = $texture/TextureRect
@onready var comp_name : Label = $Name
@onready var specs : Label = $Label

var atlas := preload("res://components/component_atlas.tres")

var component: Component

func _ready():
	if component == null:
		return
	
	comp_name.text = component.component_name
	var texture = atlas.duplicate()
	texture.region = Rect2(component.atlas_coords, component.footprint)
	img.texture = texture
	specs.text = "type: %s \n price: €%s" % [component.component_type, component.cost]


func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Global.selected_component = component
