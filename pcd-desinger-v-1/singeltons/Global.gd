extends Node

signal toolChanged(toolName: String)
enum MODE {ARCADE, SIMULATOR}

var current_mode: MODE = MODE.ARCADE

var unlocked_components: Array[Component] = []
