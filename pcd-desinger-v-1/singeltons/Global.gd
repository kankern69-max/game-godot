extends Node

signal toolChanged(toolName: String)
signal componentPlaced

var CableColor: Color = Color(1.0, 0.0, 0.0, 1.0)
enum MODE {ARCADE, SIMULATOR}

var current_mode: MODE = MODE.ARCADE

const components: Array[Component] = [preload("res://components/component_resources/resistors/resistor_220.tres"), 
preload("res://components/component_resources/resistors/resistor_330.tres"), preload("res://components/component_resources/resistors/resistor_1k.tres"), 
preload("res://components/component_resources/resistors/resistor_4k7.tres"), preload("res://components/component_resources/resistors/resistor_10k.tres"), 
preload("res://components/component_resources/resistors/resistor_100k.tres"),]

var unlocked_components: Array[Component] = [components[0], components[1], components[2], components[3], components[4], components[5],]
var selected_component: Component
