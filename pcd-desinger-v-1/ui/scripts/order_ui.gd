extends Panel

@onready var panel: Panel = $"."
@onready var vbox: VBoxContainer = $ScrollContainer/orders
@onready var AcceptedOrderPanel: Panel = $AcceptedOrder

@onready var buyerImg: TextureRect = $AcceptedOrder/buyerImg/TextureRect
@onready var nameLabel: Label = $AcceptedOrder/Name
@onready var moneyLabel: Label = $AcceptedOrder/OrderMoney
@onready var typeLabel: Label = $AcceptedOrder/OrderType
@onready var detailsLabel: Label = $AcceptedOrder/OrderDetails

var atlas_texture := preload("res://ui/assets/buyers.png")
var tile_scene: PackedScene = preload("res://ui/order_tile.tscn")
var open: bool

func _ready():
	if Global.current_mode == Global.MODE.SANDBOX:
		visible = false
	Orders.order_activated.connect(_refresh.unbind(1))
	Orders.order_completed.connect(_refresh.unbind(1))
	Orders.orders_changed.connect(_refresh)
	_refresh()

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

func _refresh() -> void:
	var has_active: bool = Orders.active_order != null
	vbox.visible = not has_active
	AcceptedOrderPanel.visible = has_active
	
	for child in vbox.get_children():
		vbox.remove_child(child)
		child.queue_free()
	
	for order in Orders.generated_orders:
		var tile = tile_scene.instantiate()
		tile.order = order
		vbox.add_child(tile)
	
	if has_active:
		_show_accepted(Orders.active_order)

func _show_accepted(order: OrderResource) -> void:
	var img := AtlasTexture.new()
	img.atlas = atlas_texture
	img.region = Rect2(Vector2i(10 * order.buyer_number, 0), Vector2i(10, 16))
	buyerImg.texture = img
	
	nameLabel.text = order.buyer_name
	typeLabel.text = order.title
	moneyLabel.text = "money: €%s\nreasearch points: %s" % [order.reward_money, order.reward_points]
	var lines: Array[String] = []
	for r in order.requirements:
		lines.append("%dx %s" % [r.count, Component.type.keys()[r.component_type]])
	detailsLabel.text = "\n".join(lines)
