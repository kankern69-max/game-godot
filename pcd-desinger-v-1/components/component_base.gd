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

var is_closed: bool = true
var _is_being_held: bool = false

const TOUCH_RADIUS: float = 6.0 

func _ready():
	if not component_data:
		push_error("No component_data assigned to %s" % name)
		return
	
	var texture = atlas.duplicate()
	texture.region = Rect2(component_data.atlas_coords, component_data.footprint)
	sprite.texture = texture
	sprite.centered = false
	sprite.offset = - Vector2(component_data.pin_offset)
	
	if component_data.component_type == Component.type.switch:
		var s_type = component_data.get("switch_type") if "switch_type" in component_data else "Toggle"
		if s_type == "PushButton":
			is_closed = false
		update_visuals()
	
	add_to_group("circuit_components")

func _input(event: InputEvent) -> void:
	if _is_being_held and event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			handle_switch_release()
			update_all_circuits(get_tree())

func handle_switch_press() -> void:
	if not component_data or component_data.component_type != Component.type.switch:
		return

	var s_type = component_data.get("switch_type") if "switch_type" in component_data else "Toggle"
	
	if s_type == "PushButton":
		is_closed = true
		_is_being_held = true
	else:
		is_closed = not is_closed
		
	update_visuals()

func handle_switch_release() -> void:
	if not component_data or component_data.component_type != Component.type.switch:
		return

	var s_type = component_data.get("switch_type") if "switch_type" in component_data else "Toggle"
	
	if s_type == "PushButton":
		is_closed = false
		_is_being_held = false
		update_visuals()

func toggle_state() -> void:
	handle_switch_press()

func is_conducting(entered_pin_index: int = -1) -> bool:
	if not component_data:
		return true

	if component_data.component_type == Component.type.switch:
		return is_closed

	if component_data is Diode or component_data.component_type == Component.type.diode:
		return entered_pin_index == 1

	return true

func update_visuals() -> void:
	if component_data and component_data.component_type == Component.type.switch:
		if not is_closed:
			sprite.modulate = Color(0.5, 0.5, 0.5) 
		else:
			sprite.modulate = Color(1.0, 1.0, 1.0) 

func contains_point(global_point: Vector2) -> bool:
	if not component_data:
		return global_position.distance_to(global_point) < 12.0
	
	var fp = Vector2(component_data.footprint)
	var offset = Vector2(component_data.pin_offset)
	var local_pos = to_local(global_point)
	var rect = Rect2(-offset, fp)
	return rect.has_point(local_pos)

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
		return 0.0
	if component_data is Resistor or "resistance" in component_data:
		return component_data.resistance
	if component_data is Battery or "internal_resistance" in component_data:
		return component_data.internal_resistance
	return 0.0

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
			var entered_pin_index: int = -1

			for i in range(c_pins.size()):
				if c_pins[i].distance_to(curr_pos) <= TOUCH_RADIUS:
					entered_pin_index = i
					break

			if entered_pin_index != -1:
				if comp.is_conducting(entered_pin_index):
					powered_components[comp] = true
					for i in range(c_pins.size()):
						if i != entered_pin_index:
							queue.append(c_pins[i])

	if is_closed_loop:
		var battery_v: float = 5.0
		var battery_r: float = 0.0
		var max_i: float = 0.0

		if component_data is Battery:
			battery_v = component_data.voltage
			battery_r = component_data.internal_resistance
			max_i = component_data.max_current
		elif "voltage" in component_data and component_data.voltage > 0.0:
			battery_v = component_data.voltage

		var total_r: float = battery_r
		for comp in powered_components.keys():
			total_r += comp._get_resistance()

		if total_r <= 0.001:
			total_r = 0.001

		var circuit_current: float = battery_v / total_r
		if max_i > 0.0 and circuit_current > max_i:
			circuit_current = max_i

		self.is_powered = true
		self.voltage = battery_v
		self.current = circuit_current
		self.update_simulation()

		for comp in powered_components.keys():
			comp.is_powered = true
			comp.current = circuit_current
			comp.voltage = circuit_current * comp._get_resistance()
			comp.update_simulation()

		for cable in powered_cables.keys():
			_set_cable_powered(cable, true, battery_v, circuit_current)

static func _get_line_from_cable(cable: Node) -> Line2D:
	if cable is Line2D:
		return cable as Line2D
	elif cable.has_node("Line2D"):
		return cable.get_node("Line2D") as Line2D
	return null

static func _set_cable_powered(cable: Node, powered: bool, v: float = 5.0, i: float = 1.0):
	if "voltage" in cable:
		cable.voltage = v if powered else 0.0
		if "current" in cable:
			cable.current = i if powered else 0.0
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
