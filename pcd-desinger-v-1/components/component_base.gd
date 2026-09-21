extends Node2D
class_name Base_component

@onready var sprite: Sprite2D = $Sprite2D
const atlas := preload("res://components/component_atlas.tres")

@export var component_data: Component

var voltage: float
var current: float
var power: float
var is_powered: bool = false
var connected_components: Array[Base_component] = []

func _ready():
	if not component_data:
		push_error("No component_data assigned to %s" % name)
		return
	
	var texture = atlas.duplicate()
	texture.region = Rect2(component_data.atlas_coords, component_data.footprint)
	sprite.texture = texture
	
	add_to_group("circuit_components")

func connect_to(other: Base_component):
	if other not in connected_components:
		connected_components.append(other)

func update_simulation():
	if Global.current_mode == Global.MODE.ARCADE:
		_update_arcade()
	else:
		_update_simulator()

	_update_visuals()

func _update_arcade():
	var visited = {}
	is_powered = _has_power_path(visited)
	
	if is_powered:
		current = 1.0
	else:
		current = 0.0

func _has_power_path(visited: Dictionary) -> bool:
	if self in visited:
		return false
	visited[self] = true
	
	if component_data.component_type == Component.type.battery:
		return true
	
	for comp in connected_components:
		if comp._has_power_path(visited):
			return true
	
	return false

func _update_simulator():
	var resistance = _get_resistance()
	if resistance > 0 and connected_components.size() > 0:
		var voltage_drop = voltage - connected_components[0].voltage
		current = abs(voltage_drop / resistance)
	else:
		current = 0.0
	
	power = current * current * resistance if resistance > 0 else 0.0
	
func _update_visuals():
	pass
	
func _get_resistance() -> float:
	match component_data.component_type:
		Component.type.resistor:
			return component_data.resistance
		_:
			return 0.0

func set_voltage(v: float):
	voltage = v
	
func get_voltage() -> float:
	if component_data.component_type == Component.type.battery:
		return 5.0
	return voltage
