extends Panel

@onready var panel: Panel = $"."
@onready var vbox: VBoxContainer = $ScrollContainer/orders
@onready var AcceptedOrderPanel: Panel = $AcceptedOrder

@onready var buyerImg: TextureRect = $AcceptedOrder/buyerImg/TextureRect
@onready var nameLabel: Label = $AcceptedOrder/Name

var atlas_texture := preload("res://ui/assets/buyers.png")
var tile_scene: PackedScene = preload("res://ui/order_tile.tscn")
var open: bool

func _ready():
	Orders.order_activated.connect(_update_order_ui)

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

func _process(_delta):
	if vbox.get_child_count() != Orders.generated_orders.size():
		_update_order_ui()
		
func _update_order_ui() -> void:
	vbox.visible = Orders.active_order == null
	AcceptedOrderPanel.visible = !vbox.visible
		
	for child in vbox.get_children():
		child.queue_free()
	
	for order in Orders.generated_orders:
		var tile = tile_scene.instantiate()
		tile.order = order
		vbox.add_child(tile)
	
	if AcceptedOrderPanel.visible:
		var img := AtlasTexture.new()
		img.atlas = atlas_texture.duplicate()
		img.region = Rect2(Vector2i(0 + (10 * Orders.active_order.buyer_number), 0), Vector2i(10,16))
		buyerImg.texture = img
		nameLabel.text = Orders.active_order.buyer_name 
