extends Node

signal toolChanged(toolName: String)
enum MODE {ARCADE, SIMULATOR}

var current_mode: MODE = MODE.ARCADE

var capacitor = preload("res://components/component_resources/Capacitor_1.tres")
var diode = preload("res://components/component_resources/Diode_1.tres")
var unlocked_components: Array[Component] = [capacitor, diode]
