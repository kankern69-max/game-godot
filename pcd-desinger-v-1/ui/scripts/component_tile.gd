extends Panel

@onready var img: TextureRect = $texture/TextureRect
@onready var comp_name : Label = $Name
@onready var specs : Label = $Label
@onready var click: AudioStreamPlayer2D = $AudioStreamPlayer2D

var atlas := preload("res://components/component_atlas.tres")

var component: Component

var component_type_names = {
	0: "resistor",
	1: "capacitor",
	2: "inductor",
	3: "diode",
	4: "led",
	5: "transistor",
	6: "ic",
	7: "switch",
	8: "battery",
	9: "ground",
	10: "potentiometer",
	11: "fuse",
	12: "buzzer",
	13: "motor"
}


func _ready():
	if component == null:
		return
	
	comp_name.text = component.component_name
	var texture = atlas.duplicate()
	texture.region = Rect2(component.atlas_coords, component.footprint)
	img.texture = texture
	specs.text = "type: %s \n price: €%s" % [component_type_names[component.component_type], component.cost]


func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		click.play()
		await click.finished
		Global.selected_component = component
		Global.toolChanged.emit("PLACE")
