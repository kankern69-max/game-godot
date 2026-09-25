extends Node

signal toolChanged(toolName: String)
signal componentPlaced

var CableColor: Color = Color(1.0, 0.0, 0.0, 1.0)
enum MODE {ARCADE, SIMULATOR}

var current_mode: MODE = MODE.ARCADE

const components: Dictionary = {
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

var unlocked_components: Array[String] = ["resistor_220", "resistor_330", "resistor_1k", "resistor_4k7", "resistor_10k", "resistor_100k", "capacitor_100n_cer", "capacitor_10n_cer", "cpacitor_10u_elec", "inductor_10u", "inductor_100u", "inductor_1m", "diode_1n4001", "diode_1n4148", "led_blue_5mm", "led_green_5mm", "led_red_5mm", "battery_5v", "ground", "switch_pushbutton", "switch_toggle"]
var selected_component: Component
