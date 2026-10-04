extends Node

signal order_activated(order: OrderResource)
signal order_completed(order: OrderResource)

var all_orders: Dictionary = {
	"basic_circuit": preload("res://orders/order_types/basic_circuit.tres")
}
var unlocked_orders: Array[OrderResource]


const MAX_ORDERS: int = 10
const MIN_ORDERS: int = 1
var generated_orders: Array[OrderResource]

var active_order: OrderResource

func _ready():
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_check_orders)
	add_child(timer)
	timer.start()
	generate_order()

func _process(_delta):
	generate_order()

func unlock_order(order_id: String) -> void:
	var order: OrderResource = all_orders[order_id]
	if order == null:
		return
	unlocked_orders.append(order)

func activate(order: OrderResource) -> void:
	if active_order != null:
		return
	if not unlocked_orders.has(order):
		return
	
	active_order = order
	order_activated.emit()

func _check_orders() -> void:
	if active_order == null:
		return
	var comps := get_tree().get_nodes_in_group("circuit_components")
	if active_order.is_coplete(comps):
		_complete(active_order)

func _complete(order: OrderResource) -> void:
	Global.money += order.reward_money
	Global.reaserch_points += order.reward_points
	order_completed.emit(order)
	active_order = null

func generate_order() -> void:
	if generated_orders.size() >= MAX_ORDERS:
		return
	if unlocked_orders.size() <= 0:
		return
	var order: OrderResource = unlocked_orders[randi_range(0, unlocked_orders.size() -1)]
	generated_orders.append(order)
