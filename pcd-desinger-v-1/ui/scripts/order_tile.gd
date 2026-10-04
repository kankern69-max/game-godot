extends Panel

@onready var NameLabel: Label = $Name
@onready var buyerImg: TextureRect = $buyerImg/TextureRect
@onready var pointsLabel: Label = $Label

var atlas_texture := preload("res://ui/assets/buyers.png") 
var order: OrderResource

const BUYERS: Array = ["person 1", "person 2", "person 3"]

func _ready():	
	if order == null:
		return
	
	var buyer: int = randi_range(0, 2)
	var buyer_name: String = BUYERS[buyer]
	order.buyer_name = buyer_name
	order.buyer_number = buyer
	
	NameLabel.text = order.buyer_name
	var img := AtlasTexture.new()
	img.atlas = atlas_texture.duplicate()
	img.region = Rect2(Vector2i(0 + (10 * order.buyer_number), 0), Vector2i(10,16))
	buyerImg.texture = img
	pointsLabel.text = "money: €%s \n recearch points: %s" % [str(order.reward_money), str(order.reward_points)]


func _on_button_pressed():
	Orders.activate(order)
