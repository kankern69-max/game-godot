extends Node

signal toolChanged(toolName: String)
var CableColor: Color = Color(1.0, 0.0, 0.0, 1.0)
enum MODE {ARCADE, SIMULATOR}

var current_mode: MODE = MODE.ARCADE

var unlocked_components: Array[Component] = []
var selected_component: Component
