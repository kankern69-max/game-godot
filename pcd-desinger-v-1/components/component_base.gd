extends Node2D
class_name Base_component

@onready var sprite: Sprite2D = $Sprite2D
const atlas := preload("res://components/component_atlas.tres")

@export var component_data: Component

var voltage: float = 0.0
var current: float = 0.0
var power: float = 0.0
var is_powered: bool = false
var connected_components: Array[Base_component] = []


const TOUCH_RADIUS: float = 2.0 

func _ready():
	if not component_data:
		push_error("No component_data assigned to %s" % name)
		return
	
	var texture = atlas.duplicate()
	texture.region = Rect2(component_data.atlas_coords, component_data.footprint)
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = - Vector2(component_data.pin_offset)
	
	add_to_group("circuit_components")

func get_pin_positions_global() -> Array[Vector2]:
	var pins: Array[Vector2] = []
	if not component_data:
		pins.append(global_position)
		return pins

	var footprint_px = Vector2(component_data.footprint)
	var offset = Vector2(component_data.pin_offset)
	
	var left_pin_local = Vector2(4.0, footprint_px.y * 0.5) - offset
	var right_pin_local = Vector2(max(4.0, footprint_px.x - 4.0), footprint_px.y * 0.5) - offset
	
	if left_pin_local.distance_to(right_pin_local) < 2.0:
		left_pin_local.x -= 4.0
		right_pin_local.x += 4.0

	pins.append(to_global(left_pin_local))  
	pins.append(to_global(right_pin_local)) 
	return pins

func _get_resistance() -> float:
	if not component_data:
		return 1.0
	return 1.0

func update_simulation() -> void:
	power = voltage * current
	is_powered = voltage > 0.0

static func update_all_circuits(tree: SceneTree):
	var all_cables = tree.get_nodes_in_group("cables")
	var all_components = tree.get_nodes_in_group("circuit_components")

	for c in all_cables:
		_set_cable_powered(c, false)

	for comp in all_components:
		if is_instance_valid(comp):
			comp.is_powered = false
			comp.voltage = 0.0
			comp.current = 0.0

	for comp in all_components:
		if is_instance_valid(comp) and comp.component_data and comp.component_data.component_type == Component.type.battery:
			comp._evaluate_battery_circuit(all_cables, all_components)

func _evaluate_battery_circuit(all_cables: Array, all_components: Array):
	var pins = get_pin_positions_global()
	if pins.size() < 2:
		return

	var target_pin_minus: Vector2 = pins[0]  
	var start_pin_plus: Vector2 = pins[1]   

	var queue: Array[Vector2] = [start_pin_plus]
	var visited_points := {}
	var powered_cables := {}
	var powered_components := {}
	
	var is_closed_loop = false

	while queue.size() > 0:
		var curr_pos = queue.pop_front()
		
		if curr_pos.distance_to(target_pin_minus) <= TOUCH_RADIUS and curr_pos != start_pin_plus:
			is_closed_loop = true

		var pos_key = Vector2i(round(curr_pos.x), round(curr_pos.y))
		if pos_key in visited_points:
			continue
		visited_points[pos_key] = true


		for cable in all_cables:
			if not is_instance_valid(cable):
				continue

			var pts: Array[Vector2] = []
			if cable.has_method("get_all_global_points"):
				pts = cable.get_all_global_points()
			else:
				var line = _get_line_from_cable(cable)
				if line:
					for p in line.points:
						pts.append(line.to_global(p))

			var touches = false
			for p in pts:
				if p.distance_to(curr_pos) <= TOUCH_RADIUS:
					touches = true
					break

			if touches:
				powered_cables[cable] = true
				for p in pts:
					queue.append(p)


		for comp in all_components:
			if not is_instance_valid(comp) or comp == self:
				continue

			var c_pins = comp.get_pin_positions_global()
			var touches_comp = false
			for p in c_pins:
				if p.distance_to(curr_pos) <= TOUCH_RADIUS:
					touches_comp = true
					break

			if touches_comp:
				powered_components[comp] = true
				for p in c_pins:
					queue.append(p)

	if is_closed_loop:
		self.is_powered = true
		self.voltage = 5.0
		self.current = 1.0

		for cable in powered_cables.keys():
			_set_cable_powered(cable, true)

		for comp in powered_components.keys():
			comp.is_powered = true
			comp.voltage = 5.0
			comp.current = 1.0

static func _get_line_from_cable(cable: Node) -> Line2D:
	if cable is Line2D:
		return cable as Line2D
	elif cable.has_node("Line2D"):
		return cable.get_node("Line2D") as Line2D
	return null

static func _set_cable_powered(cable: Node, powered: bool):
	if "voltage" in cable:
		cable.voltage = 5.0 if powered else 0.0
		if "current" in cable:
			cable.current = 1.0 if powered else 0.0
		if "power" in cable:
			cable.power = cable.voltage * cable.current
	
	if cable.has_method("set_powered"):
		cable.call("set_powered", powered)
	elif cable.has_method("update_visuals"):
		cable.call("update_visuals")
	else:
		var line = _get_line_from_cable(cable)
		if line:
			line.default_color = Color(1.0, 0.85, 0.2) if powered else Color(0.35, 0.35, 0.35)
