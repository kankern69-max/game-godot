extends Node

const SOLVER_ITERATIONS = 20

var components: Array[Base_component] = []
var batteries: Array[Base_component] = []
var ground: Base_component

func _ready():
	if Global.has_signal("componentPlaced"):
		Global.componentPlaced.connect(_rebuild_graph)
	_rebuild_graph()

func _rebuild_graph():
	components.assign(get_tree().get_nodes_in_group("circuit_components"))
	
	batteries = components.filter(func(c): return is_instance_valid(c) and c.component_data and c.component_data.component_type == Component.type.battery)
	
	var grounds = components.filter(func(c): return is_instance_valid(c) and c.component_data and c.component_data.component_type == Component.type.ground)
	ground = grounds[0] if grounds.size() > 0 else null

func _process(_delta):
	# Update het volledige netwerk en controleer op gesloten stroomkringen
	Base_component.update_all_circuits(get_tree())
	
	for comp in components:
		if is_instance_valid(comp):
			comp.update_simulation()
