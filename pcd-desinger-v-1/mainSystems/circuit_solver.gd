extends RefCounted
class_name CircuitSolver

const GMIN := 1e-9
const R_MIN := 0.001
const TOUCH_RADIUS := Base_component.TOUCH_RADIUS
const I_EPS := 1e-6

class Elem:
	var a: int
	var b: int
	var g: float
	var v_src: float = 0.0
	var kind: String = "res"   # "res", "src", "diode"
	var on: bool = false
	var comp: Base_component

var _parent: Array[int] = []

static func run(tree: SceneTree) -> Dictionary:
	return CircuitSolver.new()._run(tree)

func _make() -> int:
	_parent.append(_parent.size())
	return _parent.size() - 1

func _find(x: int) -> int:
	while _parent[x] != x:
		_parent[x] = _parent[_parent[x]]
		x = _parent[x]
	return x

func _union(a: int, b: int) -> void:
	var ra := _find(a)
	var rb := _find(b)
	if ra != rb:
		_parent[ra] = rb

func _run(tree: SceneTree) -> Dictionary:
	var comps: Array = tree.get_nodes_in_group("circuit_components")
	var cables: Array = tree.get_nodes_in_group("cables")
	var problems := {}

	for c in cables:
		Base_component._set_cable_powered(c, false)
	for comp in comps:
		if is_instance_valid(comp):
			comp.is_powered = false
			comp.voltage = 0.0
			comp.current = 0.0
			comp.update_visuals()

	var cable_id := {}
	var cable_pts := {}
	for cable in cables:
		if not is_instance_valid(cable):
			continue
		cable_id[cable] = _make()
		cable_pts[cable] = _cable_points(cable)

	var pin_id := {}
	var pin_pos := {}
	for comp in comps:
		if not is_instance_valid(comp) or comp.is_queued_for_deletion() or comp.is_ghost or not comp.component_data:
			continue
		var pos: Array = comp.get_pin_positions_global()
		var ids: Array[int] = []
		for _p in pos:
			ids.append(_make())
		pin_id[comp] = ids
		pin_pos[comp] = pos

	var cable_list: Array = cable_id.keys()
	for i in cable_list.size():
		var c1 = cable_list[i]
		for j in range(i + 1, cable_list.size()):
			var c2 = cable_list[j]
			if _layer(c1) == _layer(c2) and _points_touch(cable_pts[c1], cable_pts[c2]):
				_union(cable_id[c1], cable_id[c2])
		for comp in pin_id.keys():
			for k in pin_id[comp].size():
				if _points_touch(cable_pts[c1], [pin_pos[comp][k]]):
					_union(cable_id[c1], pin_id[comp][k])

	var comp_list: Array = pin_id.keys()
	for i in comp_list.size():
		for j in range(i + 1, comp_list.size()):
			var ca = comp_list[i]
			var cb = comp_list[j]
			for k in pin_id[ca].size():
				for m in pin_id[cb].size():
					if pin_pos[ca][k].distance_to(pin_pos[cb][m]) <= TOUCH_RADIUS:
						_union(pin_id[ca][k], pin_id[cb][m])

	var ground_terminal := -1
	for comp in comp_list:
		if comp.component_data.component_type != Component.type.ground:
			continue
		for t in pin_id[comp]:
			if ground_terminal == -1:
				ground_terminal = t
			else:
				_union(ground_terminal, t)

	var net_index := {}
	var net_of := func(terminal: int) -> int:
		var r := _find(terminal)
		if not net_index.has(r):
			net_index[r] = net_index.size()
		return net_index[r]

	var elems: Array[Elem] = []
	var battery_minus_net := -1
	for comp in comp_list:
		if comp.is_burnt:
			continue
		var data: Component = comp.component_data
		var ids: Array = pin_id[comp]
		if ids.size() < 2:
			continue
		var na: int = net_of.call(ids[0])
		var nb: int = net_of.call(ids[1])
		var e := Elem.new()
		e.comp = comp
		e.a = na
		e.b = nb
		match data.component_type:
			Component.type.battery:
				var bat := data as Battery
				e.kind = "src"
				e.a = nb
				e.b = na
				e.v_src = bat.voltage
				e.g = 1.0 / maxf(bat.internal_resistance, 0.01)
				if battery_minus_net == -1:
					battery_minus_net = na
			Component.type.diode, Component.type.led:
				var d := data as Diode
				e.kind = "diode"
				e.a = nb
				e.b = na
				e.v_src = d.forward_voltage
				e.g = 1.0 / 5.0
			Component.type.resistor:
				e.g = 1.0 / maxf((data as Resistor).resistance, R_MIN)
			Component.type.inductor:
				e.g = 1.0 / maxf((data as Inductor).resistance, R_MIN)
			Component.type.switch:
				if not comp.is_closed:
					continue
				e.g = 1.0 / maxf((data as Switch).contact_resistance, R_MIN)
			_:
				continue
		elems.append(e)

	if elems.is_empty():
		return problems

	var ground_net := -1
	if ground_terminal != -1:
		ground_net = net_of.call(ground_terminal)
	else:
		ground_net = battery_minus_net
	if ground_net == -1:
		return problems

	print("nets=", net_index.size(), " elems=", elems.size(), " ground=", ground_net)

	var n := net_index.size()
	var v := PackedFloat64Array()
	v.resize(n)

	for _iter in 20:
		v = _solve_once(elems, n, ground_net)
		var changed := false
		for e in elems:
			if e.kind != "diode":
				continue
			var vd := v[e.a] - v[e.b]
			if e.on and (vd - e.v_src) < 0.0:
				e.on = false
				changed = true
			elif not e.on and vd > e.v_src:
				e.on = true
				changed = true
		if not changed:
			break

	var net_current := PackedFloat64Array()
	net_current.resize(n)
	for e in elems:
		var vab := v[e.a] - v[e.b]
		var i := 0.0
		match e.kind:
			"res":
				i = vab * e.g
			"src":
				i = (e.v_src - vab) * e.g
			"diode":
				i = (vab - e.v_src) * e.g if e.on else 0.0
		i = absf(i)
		print(e.comp.component_data.component_name, "  V=", snappedf(vab, 0.001), "  I=", snappedf(i, 0.0001))
		net_current[e.a] = maxf(net_current[e.a], i)
		net_current[e.b] = maxf(net_current[e.b], i)

		if i < I_EPS:
			e.comp.voltage = 0.0
			e.comp.current = 0.0
		else:
			e.comp.voltage = absf(vab) if e.kind != "src" else e.v_src
			e.comp.current = i
		e.comp.update_simulation()

		var reason := _check_limits(e.comp, i, absf(vab))
		if reason != "":
			problems[e.comp] = reason

	for cable in cable_id.keys():
		var root := _find(cable_id[cable])
		if not net_index.has(root):
			continue
		var net: int = net_index[root]
		var powered := net_current[net] >= I_EPS
		Base_component._set_cable_powered(cable, powered, absf(v[net] - v[ground_net]), net_current[net])

	return problems

func _check_limits(comp: Base_component, i: float, v: float) -> String:
	var data: Component = comp.component_data
	if data.power_rating > 0.0 and i * v > data.power_rating:
		return "overpower"
	match data.component_type:
		Component.type.diode, Component.type.led:
			if (data as Diode).max_current > 0.0 and i > (data as Diode).max_current:
				return "overcurrent"
		Component.type.battery:
			if (data as Battery).max_current > 0.0 and i > (data as Battery).max_current:
				return "overcurrent"
	return ""

func _solve_once(elems: Array[Elem], n: int, ground: int) -> PackedFloat64Array:
	var G: Array = []
	var rhs: Array = []
	for r in n:
		var row: Array = []
		row.resize(n)
		row.fill(0.0)
		row[r] = GMIN
		G.append(row)
		rhs.append(0.0)

	for e in elems:
		var g: float = e.g
		if e.kind == "diode" and not e.on:
			g = GMIN
		G[e.a][e.a] += g
		G[e.b][e.b] += g
		G[e.a][e.b] -= g
		G[e.b][e.a] -= g
		if e.kind == "src" or (e.kind == "diode" and e.on):
			rhs[e.a] += g * e.v_src
			rhs[e.b] -= g * e.v_src

	for c in n:
		G[ground][c] = 1.0 if c == ground else 0.0
	rhs[ground] = 0.0
	return _gauss(G, rhs, n)

func _gauss(G: Array, rhs: Array, n: int) -> PackedFloat64Array:
	for col in n:
		var piv := col
		for r in range(col + 1, n):
			if absf(G[r][col]) > absf(G[piv][col]):
				piv = r
		if absf(G[piv][col]) < 1e-18:
			continue
		if piv != col:
			var tmp = G[piv]
			G[piv] = G[col]
			G[col] = tmp
			var t2 = rhs[piv]
			rhs[piv] = rhs[col]
			rhs[col] = t2
		for r in range(col + 1, n):
			var f: float = G[r][col] / G[col][col]
			if f == 0.0:
				continue
			for c in range(col, n):
				G[r][c] -= f * G[col][c]
			rhs[r] -= f * rhs[col]
	var x := PackedFloat64Array()
	x.resize(n)
	for r in range(n - 1, -1, -1):
		var s: float = rhs[r]
		for c in range(r + 1, n):
			s -= G[r][c] * x[c]
		x[r] = s / G[r][r] if absf(G[r][r]) > 1e-18 else 0.0
	return x

func _layer(cable: Node) -> String:
	var l = cable.get("layer_key")
	return l if l != null else ""

func _cable_points(cable: Node) -> Array[Vector2]:
	var pts: Array[Vector2] = []
	if cable.has_method("get_all_global_points"):
		pts = cable.get_all_global_points()
	else:
		var line := Base_component._get_line_from_cable(cable)
		if line:
			for p in line.points:
				pts.append(line.to_global(p))
	return pts

func _points_touch(a: Array, b: Array) -> bool:
	for p in a:
		for q in b:
			if p.distance_to(q) <= TOUCH_RADIUS:
				return true
	return false
