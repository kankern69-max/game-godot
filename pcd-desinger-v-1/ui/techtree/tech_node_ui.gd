extends Panel

@export var tech_data: TechNodeResource

@onready var texture_rect: TextureRect = $MarginContainer/VBoxContainer/TextureRect
@onready var label: Label = $MarginContainer/VBoxContainer/Label

const ATLAS_SHEET: Texture2D = preload("res://components/texture_v1.png")

func _ready() -> void:
	if Global.has_signal("tech_unlocked"):
		Global.tech_unlocked.connect(_on_tech_unlocked)
	setup_visuals()

func setup_visuals() -> void:
	if not tech_data:
		return
	
	label.text = tech_data.title
	
	var atlas_tex := AtlasTexture.new()
	atlas_tex.atlas = ATLAS_SHEET
	
	atlas_tex.region = Rect2(tech_data.img_atlas, tech_data.img_size)
	
	texture_rect.texture = atlas_tex
	update_state_visuals()

func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if tech_data and tech_data.can_unlock():
			Global.unlock_tech(tech_data)

func _on_tech_unlocked(_tech_id: String) -> void:
	update_state_visuals()

func update_state_visuals() -> void:
	if not tech_data:
		return
	if Global.unlocked_techs.has(tech_data.id):
		modulate = Color.GREEN
	elif tech_data.can_unlock():
		modulate = Color.WHITE
	else:
		modulate = Color.DARK_GRAY
