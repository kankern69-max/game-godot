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
	"cpacitor_10u_elec": preload("res://components/component_resources/capacitors/capacitor_10u_elec.tres")
}

var unlocked_components: Array[String] = ["resistor_220", "resistor_330", "resistor_1k", "resistor_4k7", "resistor_10k", "resistor_100k", "capacitor_100n_cer", "capacitor_10n_cer", "cpacitor_10u_elec"]
var selected_component: Component
