extends Node

signal toolChanged(toolName: String)
signal componentPlaced

signal component_unlocked(component_id: String)
signal tech_unlocked(tech_id: String)

var CableColor: Color = Color(1.0, 0.0, 0.0, 1.0)
enum MODE {ARCADE, SIMULATOR}

var current_mode: MODE = MODE.ARCADE

var reaserch_points: int
var money: float

var selected_component: Component

const components_paths: Dictionary = {
	"resistor_220": preload("res://components/component_resources/resistors/resistor_220.tres"), 
	"resistor_330": preload("res://components/component_resources/resistors/resistor_330.tres"), 
	"resistor_1k": preload("res://components/component_resources/resistors/resistor_1k.tres"), 
	"resistor_4k7": preload("res://components/component_resources/resistors/resistor_4k7.tres"),
	"resistor_10k": preload("res://components/component_resources/resistors/resistor_10k.tres"), 
	"resistor_100k": preload("res://components/component_resources/resistors/resistor_100k.tres"),
	"capacitor_100n_cer": preload("res://components/component_resources/capacitors/capacitor_100n_cer.tres"),
	"capacitor_10n_cer": preload("res://components/component_resources/capacitors/capacitor_10n_cer.tres"),
	"cpacitor_10u_elec": preload("res://components/component_resources/capacitors/capacitor_10u_elec.tres"),
	"inductor_10u": preload("res://components/component_resources/inductors/inductor_10u.tres"),
	"inductor_100u": preload("res://components/component_resources/inductors/inductor_100u.tres"),
	"inductor_1m": preload("res://components/component_resources/inductors/inductor_1m.tres"),
	"diode_1n4001": preload("res://components/component_resources/Diodes/1N4001 Diode (rectifier).tres"),
	"diode_1n4148": preload("res://components/component_resources/Diodes/1N4148 Diode (signal).tres"),
	"led_blue_5mm": preload("res://components/component_resources/LED/Blue LED (5mm).tres"),
	"led_green_5mm": preload("res://components/component_resources/LED/Green LED (5mm).tres"),
	"led_red_5mm": preload("res://components/component_resources/LED/Red LED (5mm).tres"),
	"battery_5v": preload("res://components/component_resources/Power/5V Battery (USB-style).tres"),
	"ground": preload("res://components/component_resources/Power/Ground.tres"),
	"switch_pushbutton": preload("res://components/component_resources/Switches/Pushbutton Switch.tres"),
	"switch_toggle": preload("res://components/component_resources/Switches/Toggle Switch.tres")
}

var unlocked_techs: Array[String] = []

var unlocked_components: Array[String] = []

func is_component_unlocked(comp_id: String) -> bool:
	return unlocked_components.has(comp_id)

func unlock_component(comp_id: String) -> void:
	if not unlocked_components.has(comp_id):
		unlocked_components.append(comp_id)
		component_unlocked.emit(comp_id)

func unlock_tech(tech: TechNodeResource) -> bool:
	if unlocked_techs.has(tech.id) or not tech.can_unlock():
		return false
		
	unlocked_techs.append(tech.id)
	
	for comp_id in tech.unlocked_components:
		if comp_id not in unlocked_components:
			unlocked_components.append(comp_id)
	
	for order_id in tech.unlocked_orders:
		if order_id not in Orders.unlocked_orders:
			Orders.unlock_order(order_id)
	
	if tech.id.begins_with("board_expansion"):
		get_tree().call_group("pcb_board", "expand_board", 0.10)
	
	tech_unlocked.emit(tech.id)
	return true
	
