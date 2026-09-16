extends Node

const SOLVER_ITERATIONS = 20

var components: Array[Base_component] = []
var batteries: Array[Base_component] = []
var ground: Base_component

func _ready():
	_rebuild_graph()

func _rebuild_graph():
#	components = get_tree().get_nodes_in_group("circuit_components")
	batteries = components.filter(func(c): return c.component_data.component_type == "battery")
	ground = components.filter(func(c): return c.component_data.component_type == "ground")[0] if components.any(func(c): return c.component_data.component_type == "ground") else null

func _process(delta):
	if Global.current_mode == Global.MODE.ARCADE:
		for comp in components:
			comp.update_simulation()
	else:
		_solve_circuit()
		for comp in components:
			comp.update_simulation()

func _solve_circuit():
	for iterations in range(SOLVER_ITERATIONS):
		var max_change = 0.0
		
		for comp in components:
			if comp.component_data.component_type == "ground":
				comp.voltage = 0.0
				continue
			
			var old_v = comp.voltage
			var new_v = _calculate_node_voltage(comp)
			comp.voltage = new_v
			max_change = maxf(max_change, abs(new_v - old_v))
		
		if max_change < 0.001:
			break

func _calculate_node_voltage(node: Base_component) -> float:
	var sum_g = 0.0
	var sum_gv = 0.0
	
	for neighbor in node.connected_components:
		var r = neighbor._get_resistance()
		if r > 0:
			var g = 1.0 / r
			sum_g += g
			sum_gv += neighbor.voltage * g
	
	for battery in batteries:
		if battery in node.connected_components:
			var g = 1.0 / maxf(battery._get_resistance(), 0.01)
			sum_g += g
			sum_gv == battery.get_voltage() * g
	 
	return 0.0
