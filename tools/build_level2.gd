extends RefCounted

const FBX_PATH := "res://assets/levels/Futuristic_City.fbx"
const CITY_SCALE := 1.0
const CITY_Z_OFFSET := 12.0
const CITY_SKIP := ["cube_010", "ocean", "cube_251", "cube_009"]
const CORRIDOR_X0 := -52.0
const CORRIDOR_X1 := 52.0
const CORRIDOR_Z0 := -10.0
const CORRIDOR_Z1 := 3.0
const STREET_Z0 := -8.3
const STREET_Z1 := 0.2
const STREET_X0 := -50.0
const STREET_X1 := 50.0
const WALK_Z := -7.3
const ROAD_Z := -4.0

const FILES := [
	{"code": "SIGMA-01", "pos": Vector3(-40.0, 0.0, -4.5)},
	{"code": "SIGMA-02", "pos": Vector3(-31.0, 0.0, -6.5)},
	{"code": "TAU-03", "pos": Vector3(-20.0, 0.0, -3.0)},
	{"code": "TAU-04", "pos": Vector3(-11.0, 0.0, -5.5)},
	{"code": "OMEGA-05", "pos": Vector3(2.0, 0.0, -4.5)},
	{"code": "OMEGA-06", "pos": Vector3(11.0, 0.0, -6.5)},
	{"code": "PSI-07", "pos": Vector3(27.0, 0.0, -3.0)},
	{"code": "PSI-08", "pos": Vector3(37.0, 0.0, -5.5)},
]

const TERMINALS := [
	{"index": 0, "name": "NODO-SIGMA", "pos": Vector3(-35.0, 0.0, -7.0), "codes": ["SIGMA-01", "SIGMA-02"]},
	{"index": 1, "name": "NODO-TAU", "pos": Vector3(-16.0, 0.0, -7.0), "codes": ["TAU-03", "TAU-04"]},
	{"index": 2, "name": "NODO-OMEGA", "pos": Vector3(6.0, 0.0, -7.0), "codes": ["OMEGA-05", "OMEGA-06"]},
	{"index": 3, "name": "NODO-PSI", "pos": Vector3(32.0, 0.0, -7.0), "codes": ["PSI-07", "PSI-08"]},
]

const BARRIERS := [
	{"x": -26.0, "res": 1},
	{"x": -4.0, "res": 2},
	{"x": 20.0, "res": 3},
	{"x": 42.0, "res": 4},
]

const SPAWN_POINTS := [
	Vector3(-30.0, 0.0, -3.0), Vector3(-22.0, 0.0, -7.5), Vector3(-12.0, 0.0, -3.0),
	Vector3(0.0, 0.0, -7.5), Vector3(12.0, 0.0, -3.0), Vector3(22.0, 0.0, -7.5),
	Vector3(30.0, 0.0, -3.0), Vector3(38.0, 0.0, -7.5),
]

const HEALTH_PICKUPS := [
	Vector3(-33.0, 0.0, -7.5), Vector3(-6.0, 0.0, -3.0), Vector3(25.0, 0.0, -7.5), Vector3(45.0, 0.0, -3.0),
]

const AMMO_PICKUPS := [
	Vector3(-44.0, 0.0, -3.0), Vector3(-24.0, 0.0, -7.5), Vector3(-9.0, 0.0, -3.0),
	Vector3(4.0, 0.0, -7.5), Vector3(16.0, 0.0, -3.0), Vector3(28.0, 0.0, -7.5), Vector3(47.0, 0.0, -3.0),
]

const NEON_SIGNS := [
	{"x": -38.0, "z": -0.4, "c": "neon_cyan", "w": 0.5, "h": 5.0},
	{"x": -18.0, "z": -0.4, "c": "neon_magenta", "w": 0.5, "h": 6.0},
	{"x": 4.0, "z": -0.4, "c": "neon_amber", "w": 0.4, "h": 4.5},
	{"x": 24.0, "z": -0.4, "c": "neon_green", "w": 0.5, "h": 5.5},
	{"x": 40.0, "z": -0.4, "c": "neon_magenta", "w": 0.4, "h": 4.0},
]

const COVERS := [
	Vector3(-29.0, 0.0, -3.5), Vector3(-9.0, 0.0, -6.0), Vector3(14.0, 0.0, -3.5), Vector3(34.0, 0.0, -6.0),
]

var mats := {}
var _box_cache := {}

func build() -> void:
	_build_materials()
	_build_level_scene()
	print("BUILD DONE")

# ---------------------------------------------------------------- materials
func _mat(name: String, albedo: Color, metallic: float, roughness: float, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	mats[name] = m
	return m

func _build_materials() -> void:
	_mat("neon_cyan", Color(0.02, 0.35, 0.45), 0.2, 0.3, Color(0.0, 0.9, 1.0), 2.4)
	_mat("neon_magenta", Color(0.35, 0.05, 0.3), 0.2, 0.3, Color(1.0, 0.15, 0.8), 2.4)
	_mat("neon_amber", Color(0.4, 0.25, 0.03), 0.2, 0.3, Color(1.0, 0.6, 0.1), 2.0)
	_mat("neon_green", Color(0.05, 0.35, 0.12), 0.2, 0.3, Color(0.2, 1.0, 0.4), 2.0)
	_mat("metal_panel", Color(0.13, 0.15, 0.18), 0.9, 0.4)
	_mat("asphalt", Color(0.035, 0.04, 0.05), 0.1, 0.9)
	_mat("sidewalk", Color(0.11, 0.12, 0.14), 0.3, 0.75)
	_mat("pole", Color(0.08, 0.09, 0.11), 0.85, 0.45)
	_mat("cover", Color(0.16, 0.17, 0.2), 0.6, 0.5)
	_mat("hazard", Color(0.5, 0.4, 0.05), 0.3, 0.7)

# ---------------------------------------------------------------- primitives
func _box_mesh(s: Vector3) -> BoxMesh:
	var key := "%.3f_%.3f_%.3f" % [s.x, s.y, s.z]
	if not _box_cache.has(key):
		var m := BoxMesh.new()
		m.size = s
		_box_cache[key] = m
	return _box_cache[key]

func _box(parent: Node3D, n: String, pos: Vector3, size: Vector3, mat: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = _box_mesh(size)
	mi.material_override = mats[mat]
	mi.position = pos
	parent.add_child(mi)
	return mi

func _omni(parent: Node3D, n: String, pos: Vector3, color: Color, energy: float, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = n
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	parent.add_child(l)
	return l

# ---------------------------------------------------------------- city
func _accumulate(node: Node, root: Node) -> Transform3D:
	var xform: Transform3D = (node as Node3D).transform
	var p := node.get_parent()
	while p != null and p != root:
		xform = (p as Node3D).transform * xform
		p = p.get_parent()
	return xform

func _mesh_world_aabb(mi: MeshInstance3D, city: Node3D) -> AABB:
	var laabb := mi.get_aabb()
	var gt := city.transform * _accumulate(mi, city)
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for i in 8:
		var corner := Vector3(
			laabb.position.x if i & 1 else laabb.position.x + laabb.size.x,
			laabb.position.y if i & 2 else laabb.position.y + laabb.size.y,
			laabb.position.z if i & 4 else laabb.position.z + laabb.size.z)
		var w := gt * corner
		mn = mn.min(w)
		mx = mx.max(w)
	return AABB(mn, mx - mn)

func _transformed_bounds(aabb: AABB, xform: Transform3D) -> Array:
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for i in 8:
		var corner := Vector3(
			aabb.position.x if i & 1 else aabb.position.x + aabb.size.x,
			aabb.position.y if i & 2 else aabb.position.y + aabb.size.y,
			aabb.position.z if i & 4 else aabb.position.z + aabb.size.z)
		var w := xform * corner
		mn = mn.min(w)
		mx = mx.max(w)
	return [mn, mx]

func _build_city(root: Node3D) -> void:
	var ps: PackedScene = load(FBX_PATH)
	if ps == null:
		push_error("no se pudo cargar " + FBX_PATH)
		return

	var proto := ps.instantiate() as Node3D
	var ground_mi := _find_mesh(proto, "cube_010")
	if ground_mi == null:
		push_error("no se encontro el suelo de la ciudad")
		return
	var gb := _transformed_bounds(ground_mi.get_aabb(), _accumulate(ground_mi, proto))
	var gmin: Vector3 = gb[0]
	var gmax: Vector3 = gb[1]
	var origin := Vector3(-(gmin.x + gmax.x) * 0.5, -gmax.y, CITY_Z_OFFSET)
	proto.queue_free()
	print("ciudad: origen=", origin, " suelo x=", gmin.x, "..", gmax.x, " z=", gmin.z, "..", gmax.z)

	var city := ps.instantiate() as Node3D
	city.name = "FuturisticCity"
	city.set_script(load("res://scripts/CityStyler.gd"))
	city.scale = Vector3.ONE * CITY_SCALE
	city.position = origin
	city.set("clear_corridor", true)
	city.set("corridor_min", Vector2(CORRIDOR_X0, CORRIDOR_Z0))
	city.set("corridor_max", Vector2(CORRIDOR_X1, CORRIDOR_Z1))
	root.add_child(city)

	var collider := StaticBody3D.new()
	collider.name = "CityColliders"
	collider.collision_layer = 1
	collider.collision_mask = 0
	root.add_child(collider)

	var ground := StaticBody3D.new()
	ground.name = "CityGround"
	ground.collision_layer = 1
	ground.collision_mask = 0
	root.add_child(ground)
	var gs := CollisionShape3D.new()
	gs.name = "Ground"
	var gbs := BoxShape3D.new()
	gbs.size = Vector3(gmax.x - gmin.x, 1.0, gmax.z - gmin.z)
	gs.shape = gbs
	gs.position = Vector3((gmin.x + gmax.x) * 0.5 + origin.x, -0.5, (gmin.z + gmax.z) * 0.5 + origin.z)
	ground.add_child(gs)

	var meshes := 0
	var shapes := 0
	var skipped := 0
	var stack: Array[Node] = [city]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh == null:
				continue
			meshes += 1
			var lname := String(mi.name).to_lower()
			if _is_skipped(lname):
				skipped += 1
				continue
			var w := _mesh_world_aabb(mi, city)
			if _blocks_corridor(w):
				skipped += 1
				continue
			var top := maxf(w.position.y, 0.0)
			var height := w.position.y + w.size.y - top
			if height < 0.5:
				skipped += 1
				continue
			if minf(w.size.x, w.size.z) < 3.0 or maxf(w.size.x, w.size.z) < 6.0:
				skipped += 1
				continue
			var cs := CollisionShape3D.new()
			cs.name = "CS_%d" % shapes
			var bs := BoxShape3D.new()
			bs.size = Vector3(w.size.x, height, w.size.z)
			cs.shape = bs
			cs.position = Vector3(w.position.x + w.size.x * 0.5, top + height * 0.5, w.position.z + w.size.z * 0.5)
			collider.add_child(cs)
			shapes += 1
	print("ciudad: mallas=", meshes, " colisionadores=", shapes, " omitidos=", skipped)

func _is_skipped(lname: String) -> bool:
	for s in CITY_SKIP:
		if lname.contains(s):
			return true
	return false

func _blocks_corridor(b: AABB) -> bool:
	if b.size.x > 120.0 or b.size.z > 120.0:
		return false
	if b.size.y < 2.0:
		return false
	if b.position.x > CORRIDOR_X1 or b.position.x + b.size.x < CORRIDOR_X0:
		return false
	if b.position.z > CORRIDOR_Z1 or b.position.z + b.size.z < CORRIDOR_Z0:
		return false
	return true

func _find_mesh(root: Node, needle: String) -> MeshInstance3D:
	var stack: Array[Node] = [root]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		for c in cur.get_children():
			stack.append(c)
		if cur is MeshInstance3D:
			var mi := cur as MeshInstance3D
			if mi.mesh != null and String(mi.name).to_lower().contains(needle):
				return mi
	return null

# ---------------------------------------------------------------- level
func _build_level_scene() -> void:
	var root := Node3D.new()
	root.name = "Level2"

	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.006, 0.012, 0.028)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.05, 0.07, 0.12)
	env.ambient_light_energy = 1.0
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.01, 0.025, 0.06)
	env.fog_light_energy = 0.7
	env.fog_density = 0.022
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.2
	env.glow_enabled = true
	env.glow_intensity = 0.75
	env.glow_bloom = 0.1
	we.environment = env
	root.add_child(we)

	var moon := DirectionalLight3D.new()
	moon.name = "Moonlight"
	moon.light_color = Color(0.35, 0.5, 0.85)
	moon.light_energy = 0.4
	moon.shadow_enabled = false
	moon.rotation_degrees = Vector3(-55, 40, 0)
	root.add_child(moon)

	_build_city(root)
	_build_street(root)
	_build_street_props(root)
	_build_gameplay(root)

	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var player := player_scene.instantiate()
	player.name = "Player"
	player.set_scene_file_path("res://scenes/Player.tscn")
	player.position = Vector3(-46.0, 0.2, -4.0)
	root.add_child(player)

	var nova_scene: PackedScene = load("res://scenes/Nova.tscn")
	var nova := nova_scene.instantiate()
	nova.name = "Nova"
	nova.set_scene_file_path("res://scenes/Nova.tscn")
	nova.position = Vector3(-47.0, 0.0, -5.5)
	root.add_child(nova)

	_set_owner(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack failed %d" % err)
		return
	err = ResourceSaver.save(ps, "res://scenes/Level2.tscn")
	print("Level2 saved: ", err)

func _build_street(root: Node3D) -> void:
	var street := Node3D.new()
	street.name = "Street"
	root.add_child(street)

	var length := STREET_X1 - STREET_X0
	var mid := (STREET_X0 + STREET_X1) * 0.5

	_box(street, "Walkway", Vector3(mid, -0.1, WALK_Z), Vector3(length + 16.0, 0.24, 2.0), "sidewalk")
	_box(street, "Asphalt", Vector3(mid, 0.03, -3.5), Vector3(length + 8.0, 0.04, 3.0), "asphalt")
	_box(street, "LaneL", Vector3(mid, 0.07, -5.0), Vector3(length + 8.0, 0.06, 0.16), "neon_cyan")
	_box(street, "LaneR", Vector3(mid, 0.07, -2.0), Vector3(length + 8.0, 0.06, 0.16), "neon_cyan")
	_box(street, "Kerb", Vector3(mid, 0.14, -6.3), Vector3(length + 12.0, 0.4, 0.35), "metal_panel")
	_box(street, "KerbGlow", Vector3(mid, 0.36, -6.3), Vector3(length + 12.0, 0.07, 0.4), "neon_magenta")
	_box(street, "Rail", Vector3(mid, 0.55, -8.3), Vector3(length + 12.0, 1.1, 0.3), "metal_panel")
	_box(street, "RailGlow", Vector3(mid, 1.14, -8.3), Vector3(length + 12.0, 0.1, 0.36), "neon_cyan")

	var body := StaticBody3D.new()
	body.name = "StreetColliders"
	body.collision_layer = 1
	body.collision_mask = 0
	street.add_child(body)
	_add_box_shape(body, "Walkway", Vector3(mid, -0.1, WALK_Z), Vector3(length + 16.0, 0.24, 2.0))
	_add_box_shape(body, "Kerb", Vector3(mid, 0.14, -6.3), Vector3(length + 12.0, 0.4, 0.35))
	_add_box_shape(body, "Rail", Vector3(mid, 0.55, -8.3), Vector3(length + 12.0, 1.1, 0.3))
	_add_box_shape(body, "BoundS", Vector3(mid, 3.0, -8.9), Vector3(length + 16.0, 6.0, 0.5))
	_add_box_shape(body, "BoundN", Vector3(mid, 3.0, 0.6), Vector3(length + 16.0, 6.0, 0.5))
	_add_box_shape(body, "BoundW", Vector3(STREET_X0 - 4.0, 3.0, -4.5), Vector3(1.0, 6.0, 12.0))
	_add_box_shape(body, "BoundE", Vector3(STREET_X1 + 4.0, 3.0, -4.5), Vector3(1.0, 6.0, 12.0))

func _add_box_shape(parent: StaticBody3D, n: String, pos: Vector3, size: Vector3) -> void:
	var cs := CollisionShape3D.new()
	cs.name = n
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = pos
	parent.add_child(cs)

func _build_street_props(root: Node3D) -> void:
	var props := Node3D.new()
	props.name = "Props"
	root.add_child(props)

	var x := STREET_X0 + 5.0
	var i := 0
	while x < STREET_X1:
		var pole := Node3D.new()
		pole.name = "Lamp_%02d" % i
		pole.position = Vector3(x, 0.0, WALK_Z - 0.4)
		props.add_child(pole)
		_box(pole, "Post", Vector3(0, 2.6, 0), Vector3(0.18, 5.2, 0.18), "pole")
		_box(pole, "Arm", Vector3(0, 5.1, 0.9), Vector3(0.14, 0.14, 1.8), "pole")
		var head_mat := "neon_cyan" if (i % 2 == 0) else "neon_magenta"
		_box(pole, "Head", Vector3(0, 4.95, 1.7), Vector3(0.5, 0.16, 0.8), head_mat)
		var light_color := Color(0.4, 0.8, 1.0)
		if i % 2 == 1:
			light_color = Color(1.0, 0.3, 0.8)
		_omni(pole, "Light", Vector3(0, 4.6, 1.7), light_color, 2.4, 18.0)
		x += 9.0
		i += 1

	for s in NEON_SIGNS:
		var sx: float = s["x"]
		var sz: float = s["z"]
		var sh: float = s["h"]
		var sw: float = s["w"]
		var dir := -1.0 if sz >= 0.0 else 1.0
		var sign := Node3D.new()
		sign.name = "Sign_%d" % int(sx)
		sign.position = Vector3(sx, 0.0, sz)
		props.add_child(sign)
		_box(sign, "Post", Vector3(0, sh * 0.5 + 0.4, 0.25), Vector3(0.22, sh + 0.8, 0.22), "pole")
		_box(sign, "Panel", Vector3(0, sh * 0.5 + 0.4, 0), Vector3(sw, sh, 0.3), "metal_panel")
		_box(sign, "Glow", Vector3(0, sh * 0.5 + 0.4, -0.18 * dir), Vector3(sw * 0.7, sh * 0.9, 0.12), String(s["c"]))
		_omni(sign, "Light", Vector3(0, sh * 0.6, -1.4 * dir), Color(0.3, 0.9, 1.0), 2.2, 16.0)

	for c in COVERS:
		var cx: float = c.x
		var cz: float = c.z
		var cover := Node3D.new()
		cover.name = "Cover_%d" % int(cx)
		cover.position = Vector3(cx, 0.0, cz)
		props.add_child(cover)
		_box(cover, "Block", Vector3(0, 0.6, 0), Vector3(2.2, 1.2, 1.2), "cover")
		_box(cover, "Stripe", Vector3(0, 1.22, 0), Vector3(2.2, 0.06, 1.24), "hazard")

# ---------------------------------------------------------------- gameplay
func _instance(path: String, parent: Node, n: String, pos: Vector3, rot_y: float = 0.0) -> Node:
	var ps: PackedScene = load(path)
	var node: Node = ps.instantiate()
	node.name = n
	node.set_scene_file_path(path)
	node.position = pos
	node.rotation.y = rot_y
	parent.add_child(node)
	return node

func _build_gameplay(root: Node3D) -> void:
	var gameplay := Node3D.new()
	gameplay.name = "Gameplay"
	root.add_child(gameplay)

	var files := Node3D.new()
	files.name = "DataFiles"
	gameplay.add_child(files)
	for f in FILES:
		var code := String(f["code"])
		var pos: Vector3 = f["pos"]
		var node := _instance("res://scenes/DataFile.tscn", files, "File_%s" % code, pos)
		node.set("code", code)

	var terminals := Node3D.new()
	terminals.name = "Terminals"
	gameplay.add_child(terminals)
	for t in TERMINALS:
		var idx := int(t["index"])
		var tpos: Vector3 = t["pos"]
		var node := _instance("res://scenes/Terminal.tscn", terminals, "Terminal_%02d" % idx, tpos, PI * 0.5)
		node.set("index", idx)
		node.set("display_name", String(t["name"]))
		var codes: Array[String] = []
		for c in t["codes"]:
			codes.append(String(c))
		node.set("required_codes", codes)

	var barriers := Node3D.new()
	barriers.name = "Barriers"
	gameplay.add_child(barriers)
	for b in BARRIERS:
		var bx := float(b["x"])
		var barrier := StaticBody3D.new()
		barrier.name = "Barrier_%d" % int(bx)
		barrier.set_script(load("res://scripts/Barrier.gd"))
		barrier.set("required_resolutions", int(b["res"]))
		barrier.set("requires_boss", false)
		barrier.position = Vector3(bx, 0.0, 0.0)
		barriers.add_child(barrier)
		var panel := Node3D.new()
		panel.name = "Panel"
		barrier.add_child(panel)
		var bw := STREET_Z1 - STREET_Z0 - 0.4
		var bz := (STREET_Z0 + STREET_Z1) * 0.5
		_box(panel, "Field", Vector3(0, 2.6, bz), Vector3(0.35, 5.0, bw), "neon_cyan")
		_box(panel, "FrameTop", Vector3(0, 5.1, bz), Vector3(0.7, 0.5, bw + 0.4), "metal_panel")
		_box(panel, "FrameBottom", Vector3(0, 0.25, bz), Vector3(0.7, 0.5, bw + 0.4), "metal_panel")
		_omni(panel, "BarrierLight", Vector3(0, 3.0, bz), Color(0.0, 0.8, 1.0), 3.0, 14.0)
		var cs := CollisionShape3D.new()
		cs.name = "CollisionShape3D"
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.6, 5.0, bw)
		cs.shape = bs
		cs.position = Vector3(0, 2.6, bz)
		barrier.add_child(cs)

	var pickups := Node3D.new()
	pickups.name = "Pickups"
	gameplay.add_child(pickups)
	for p in HEALTH_PICKUPS:
		var hpos: Vector3 = p
		var node := _instance("res://scenes/Pickup.tscn", pickups, "Health_%d" % int(hpos.x), hpos)
		node.set("kind", 0)
		node.set("amount", 30)
	for p in AMMO_PICKUPS:
		var apos: Vector3 = p
		var node := _instance("res://scenes/Pickup.tscn", pickups, "Ammo_%d" % int(apos.x), apos)
		node.set("kind", 1)
		node.set("amount", 24)

	var spawns := Node3D.new()
	spawns.name = "SpawnPoints"
	gameplay.add_child(spawns)
	for i in SPAWN_POINTS.size():
		var sp := Node3D.new()
		sp.name = "Spawn_%02d" % i
		sp.position = SPAWN_POINTS[i]
		spawns.add_child(sp)

	var exit_holder := Node3D.new()
	exit_holder.name = "LevelExit"
	gameplay.add_child(exit_holder)
	var exit := Area3D.new()
	exit.name = "ExitPortal"
	exit.set_script(load("res://scripts/LevelExit.gd"))
	exit.set("next_scene", "res://scenes/Level1.tscn")
	exit.set("requires_boss", false)
	exit.set("enabled", false)
	exit.position = Vector3(48.0, 0.0, -4.0)
	exit_holder.add_child(exit)
	var visual := Node3D.new()
	visual.name = "Visual"
	exit.add_child(visual)
	var ring := MeshInstance3D.new()
	ring.name = "Ring"
	var torus := TorusMesh.new()
	torus.inner_radius = 1.1
	torus.outer_radius = 1.5
	ring.mesh = torus
	var emat := StandardMaterial3D.new()
	emat.albedo_color = Color(0.05, 0.3, 0.2)
	emat.emission_enabled = true
	emat.emission = Color(0.2, 1.0, 0.5)
	emat.emission_energy_multiplier = 3.0
	ring.material_override = emat
	ring.position = Vector3(0, 1.8, 0)
	visual.add_child(ring)
	var exit_light := OmniLight3D.new()
	exit_light.name = "ExitLight"
	exit_light.light_color = Color(0.2, 1.0, 0.5)
	exit_light.light_energy = 2.5
	exit_light.omni_range = 12.0
	exit_light.position = Vector3(0, 1.8, 0)
	visual.add_child(exit_light)
	var exit_label := Label3D.new()
	exit_label.name = "Label"
	exit_label.text = "SALIDA"
	exit_label.font_size = 48
	exit_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	exit_label.no_depth_test = true
	exit_label.position = Vector3(0, 3.4, 0)
	exit.add_child(exit_label)
	var exit_col := CollisionShape3D.new()
	exit_col.name = "CollisionShape3D"
	var exit_shape := BoxShape3D.new()
	exit_shape.size = Vector3(3.0, 4.0, 5.0)
	exit_col.shape = exit_shape
	exit_col.position = Vector3(0, 2.0, 0)
	exit.add_child(exit_col)

	var director := Node.new()
	director.name = "LevelDirector"
	director.set_script(load("res://scripts/LevelDirector.gd"))
	gameplay.add_child(director)
	director.set("total_resolutions", TERMINALS.size())
	director.set("combat_after", 2)
	director.set("max_alive", 5)
	director.set("level_index", 2)
	director.set("android_scene", load("res://scenes/Android.tscn"))
	director.set("projectile_scene", load("res://scenes/Projectile.tscn"))
	director.set("boss_scene", null)

	var hud_scene: PackedScene = load("res://scenes/HUD.tscn")
	var hud := hud_scene.instantiate()
	hud.name = "HUD"
	hud.set_scene_file_path("res://scenes/HUD.tscn")
	root.add_child(hud)

# ---------------------------------------------------------------- owner
func _set_owner(node: Node, owner_node: Node) -> void:
	for c in node.get_children():
		c.owner = owner_node
		if c.scene_file_path == "":
			_set_owner(c, owner_node)
