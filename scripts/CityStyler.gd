extends Node3D

@export var facade_color: Color = Color(0.09, 0.10, 0.14)
@export var panel_color: Color = Color(0.13, 0.15, 0.18)
@export var street_color: Color = Color(0.045, 0.05, 0.06)
@export var neon_a: Color = Color(0.0, 0.9, 1.0)
@export var neon_b: Color = Color(1.0, 0.15, 0.8)
@export var cast_shadows: bool = false
@export var hide_slab: bool = false
@export var hide_facade: bool = false
@export var clear_corridor: bool = true
@export var corridor_min: Vector2 = Vector2(-52.0, -7.0)
@export var corridor_max: Vector2 = Vector2(52.0, 7.0)

var _mats := {}

func _ready() -> void:
	_build_materials()
	_stylize()

func _build_materials() -> void:
	_mats["neon_a"] = _make(neon_a, 0.2, 0.3, 1.3)
	_mats["neon_b"] = _make(neon_b, 0.2, 0.3, 1.3)
	_mats["facade"] = _make(facade_color, 0.65, 0.55)
	_mats["panel"] = _make(panel_color, 0.9, 0.4)
	_mats["street"] = _make(street_color, 0.15, 0.85)
	_mats["foliage"] = _make(Color(0.04, 0.14, 0.08), 0.1, 0.9)
	_mats["trunk"] = _make(Color(0.10, 0.07, 0.05), 0.05, 0.95)

func _make(albedo: Color, metallic: float, roughness: float, energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = albedo
		m.emission_energy_multiplier = energy
	return m

func _pick(n: String) -> StandardMaterial3D:
	var lower := n.to_lower()
	if lower.contains("window"):
		return _mats["neon_a"] if (n.hash() % 2 == 0) else _mats["neon_b"]
	if lower.contains("crown"):
		return _mats["foliage"]
	if lower.contains("trunk"):
		return _mats["trunk"]
	if lower.contains("cube_251"):
		return _mats["street"]
	if lower.contains("downtown center city"):
		return _mats["facade"]
	if lower.contains("cube"):
		return _mats["panel"]
	return _mats["facade"]

func _accumulate(node: Node) -> Transform3D:
	var xform: Transform3D = (node as Node3D).transform
	var p := node.get_parent()
	while p != null and p != self:
		xform = (p as Node3D).transform * xform
		p = p.get_parent()
	return xform

func _world_bounds(mi: MeshInstance3D) -> AABB:
	var xform := transform * _accumulate(mi)
	var laabb := mi.get_aabb()
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for i in 8:
		var corner := Vector3(
			laabb.position.x if i & 1 else laabb.position.x + laabb.size.x,
			laabb.position.y if i & 2 else laabb.position.y + laabb.size.y,
			laabb.position.z if i & 4 else laabb.position.z + laabb.size.z)
		var w := xform * corner
		mn = mn.min(w)
		mx = mx.max(w)
	return AABB(mn, mx - mn)

func _blocks_corridor(b: AABB) -> bool:
	if not clear_corridor:
		return false
	if b.size.y < 2.0:
		return false
	if b.position.x > corridor_max.x or b.position.x + b.size.x < corridor_min.x:
		return false
	if b.position.z > corridor_max.y or b.position.z + b.size.z < corridor_min.y:
		return false
	return true

func _stylize() -> void:
	var stack: Array[Node] = [self]
	var count := 0
	var hidden := 0
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh == null:
				continue
			count += 1
			if not cast_shadows:
				mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var lname := String(mi.name).to_lower()
			if hide_slab and lname.contains("cube_251"):
				mi.visible = false
				continue
			if hide_facade and lname.contains("cube_009"):
				mi.visible = false
				continue
			if _blocks_corridor(_world_bounds(mi)):
				mi.visible = false
				hidden += 1
				continue
			mi.material_override = _pick(String(mi.name))
	print("CityStyler: %d mallas estilizadas (%d ocultas)" % [count, hidden])
