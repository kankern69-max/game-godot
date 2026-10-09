extends Node

signal order_activated(order: OrderResource)
signal order_completed(order: OrderResource)
signal orders_changed

var all_orders: Dictionary = {
	"basic_circuit": preload("res://orders/order_types/basic_circuit.tres")
}
var unlocked_orders: Array[OrderResource]

const MAX_ORDERS: int = 10
const MIN_ORDERS: int = 1
const SPAWN_INTERVAL: float = 8.0
const BUYERS: Array[String] = ["zim zim", "mats van zimmeren", "person 3"]
var generated_orders: Array[OrderResource]

var active_order: OrderResource

func _ready():
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_check_orders)
	add_child(timer)
	timer.start()
	
	var spawn_timer := Timer.new()
	spawn_timer.wait_time = SPAWN_INTERVAL
	spawn_timer.timeout.connect(generate_order)
	add_child(spawn_timer)
	spawn_timer.start()

func unlock_order(order_id: String) -> void:
	var order: OrderResource = all_orders[order_id]
	if order == null or unlocked_orders.has(order):
		return
	unlocked_orders.append(order)
	generate_order()

func activate(order: OrderResource) -> void:
	if active_order != null or not generated_orders.has(order):
		return
	
	active_order = order
	order_activated.emit(order)

func _check_orders() -> void:
	if active_order == null:
		return
	var comps := get_tree().get_nodes_in_group("circuit_components")
	if active_order.is_coplete(comps):
		_complete(active_order)

func _complete(order: OrderResource) -> void:
	Global.money += order.reward_money
	Global.reaserch_points += order.reward_points
	generated_orders.erase(order)
	active_order = null
	order_completed.emit(order)
	orders_changed.emit()

func generate_order() -> void:
	if generated_orders.size() >= MAX_ORDERS or unlocked_orders.is_empty():
		return
	var order: OrderResource = unlocked_orders.pick_random().duplicate()
	order.buyer_number = randi_range(0, BUYERS.size() -1)
	order.buyer_name = BUYERS[order.buyer_number]
	generated_orders.append(order)
	orders_changed.emit()
