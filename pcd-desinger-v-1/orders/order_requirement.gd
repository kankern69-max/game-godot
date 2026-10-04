extends Resource
class_name OrderRequirement

@export var component_type: Component.type
@export var count: int = 1
@export var must_be_powered: bool = true
@export var min_voltage: float = 0.0

func count_matches(components: Array) -> int:
	var n := 0
	for c in components:
		if not is_instance_valid(c) or not c.component_data:
			continue
		if c.component_data.component_type != component_type:
			continue
		if Global.current_mode == Global.MODE.SIMULATOR and c.voltage < min_voltage:
			continue
		n += 1
	return n

func is_met(components: Array) -> bool:
	return count_matches(components) >= count
