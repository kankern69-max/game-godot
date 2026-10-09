extends Panel

@onready var NameLabel: Label = $Name
@onready var buyerImg: TextureRect = $buyerImg/TextureRect
@onready var pointsLabel: Label = $Label

var atlas_texture := preload("res://ui/assets/buyers.png") 
var order: OrderResource

func _ready():	
	if order == null:
		return
	
	NameLabel.text = order.buyer_name
	var img := AtlasTexture.new()
	img.atlas = atlas_texture.duplicate()
	img.region = Rect2(Vector2i(0 + (10 * order.buyer_number), 0), Vector2i(10,16))
	buyerImg.texture = img
	pointsLabel.text = "money: €%s \n recearch points: %s" % [str(order.reward_money), str(order.reward_points)]


func _on_button_pressed():
	Orders.activate(order)
