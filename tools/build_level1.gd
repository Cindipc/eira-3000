extends RefCounted

const ZONES := [
	{"name": "Zone1_Entry", "start": -8.0, "end": 20.0, "hw": 10.0},
	{"name": "Zone2_Hall", "start": 20.0, "end": 60.0, "hw": 10.0},
	{"name": "Zone3_CombatHub", "start": 60.0, "end": 100.0, "hw": 15.0},
	{"name": "Zone4_BossArena", "start": 100.0, "end": 140.0, "hw": 20.0},
	{"name": "Zone5_Exit", "start": 140.0, "end": 170.0, "hw": 10.0},
]

const FILES := [
	{"code": "ALFA-01", "pos": Vector3(3.0, 0.0, -6.5)},
	{"code": "ALFA-02", "pos": Vector3(12.5, 0.0, 6.5)},
	{"code": "ALFA-03", "pos": Vector3(17.5, 0.0, -7.5)},
	{"code": "BRAVO-04", "pos": Vector3(27.0, 0.0, 6.2)},
	{"code": "BRAVO-05", "pos": Vector3(36.0, 0.0, -6.5)},
	{"code": "BRAVO-06", "pos": Vector3(57.0, 0.0, 6.5)},
	{"code": "CHARLIE-07", "pos": Vector3(65.0, 0.0, -9.0)},
	{"code": "CHARLIE-08", "pos": Vector3(77.0, 0.0, 8.5)},
	{"code": "DELTA-09", "pos": Vector3(94.0, 0.0, 10.0)},
	{"code": "DELTA-10", "pos": Vector3(102.0, 0.0, -11.0)},
	{"code": "DELTA-11", "pos": Vector3(107.0, 0.0, 13.0)},
	{"code": "ECHO-12", "pos": Vector3(117.0, 0.0, -13.0)},
	{"code": "ECHO-13", "pos": Vector3(129.0, 0.0, 6.0)},
	{"code": "ECHO-14", "pos": Vector3(132.0, 0.0, -12.0)},
]

const TERMINALS := [
	{"index": 0, "name": "NODO-ALFA", "pos": Vector3(14.0, 0.0, -7.5), "codes": ["ALFA-01", "ALFA-02"]},
	{"index": 1, "name": "NODO-BRAVO", "pos": Vector3(46.0, 0.0, 7.5), "codes": ["ALFA-03", "BRAVO-04"]},
	{"index": 2, "name": "NODO-CHARLIE", "pos": Vector3(68.0, 0.0, -10.5), "codes": ["BRAVO-05", "BRAVO-06"]},
	{"index": 3, "name": "NODO-DELTA", "pos": Vector3(92.0, 0.0, 9.5), "codes": ["CHARLIE-07", "CHARLIE-08"]},
	{"index": 4, "name": "NODO-ECHO", "pos": Vector3(104.0, 0.0, -12.5), "codes": ["DELTA-09", "DELTA-10", "DELTA-11"]},
	{"index": 5, "name": "NODO-FOXTROT", "pos": Vector3(112.0, 0.0, 12.0), "codes": ["ECHO-12", "ECHO-13", "ECHO-14"]},
]

const BARRIERS := [
	{"x": 20.0, "hw": 10.0, "res": 1, "boss": false},
	{"x": 60.0, "hw": 15.0, "res": 2, "boss": false},
	{"x": 100.0, "hw": 20.0, "res": 4, "boss": false},
	{"x": 140.0, "hw": 10.0, "res": 6, "boss": true},
]

const SPAWN_POINTS := [
	Vector3(40.0, 0.0, -8.0), Vector3(45.0, 0.0, 8.0), Vector3(55.0, 0.0, -10.0),
	Vector3(62.0, 0.0, 10.0), Vector3(75.0, 0.0, -13.0), Vector3(80.0, 0.0, 13.0),
	Vector3(95.0, 0.0, -14.0), Vector3(98.0, 0.0, 14.0), Vector3(108.0, 0.0, -17.0),
	Vector3(112.0, 0.0, 17.0), Vector3(125.0, 0.0, -17.0), Vector3(130.0, 0.0, 17.0),
]

const HEALTH_PICKUPS := [
	Vector3(30.0, 0.0, -5.0), Vector3(74.0, 0.0, 6.0), Vector3(97.0, 0.0, -6.0),
	Vector3(118.0, 0.0, -8.0), Vector3(134.0, 0.0, 9.0),
]

const AMMO_PICKUPS := [
	Vector3(9.0, 0.0, 6.0), Vector3(24.0, 0.0, -6.0), Vector3(50.0, 0.0, 5.0),
	Vector3(70.0, 0.0, -8.0), Vector3(88.0, 0.0, 7.0), Vector3(103.0, 0.0, -10.0),
	Vector3(127.0, 0.0, -14.0),
]

const CEIL_H := 7.0
const WALL_T := 0.5

var _box_cache := {}
var _cyl_cache := {}
var _rng := RandomNumberGenerator.new()
var mats := {}

func build() -> void:
	_rng.seed = 20240517
	_build_materials()
	_build_player_scene()
	_build_nova_scene()
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
	_mat("dark", Color(0.04, 0.05, 0.07), 0.75, 0.7)
	_mat("metal", Color(0.18, 0.22, 0.26), 0.9, 0.45)
	_mat("metal_dark", Color(0.09, 0.11, 0.14), 0.85, 0.55)
	_mat("tech", Color(0.05, 0.15, 0.25), 0.55, 0.45, Color(0.0, 0.8, 1.0), 1.2)
	_mat("steel", Color(0.22, 0.24, 0.27), 0.95, 0.35)
	_mat("graphite", Color(0.10, 0.11, 0.13), 0.4, 0.75)
	_mat("rubber", Color(0.03, 0.03, 0.035), 0.05, 0.95)
	_mat("white", Color(0.9, 0.95, 1.0), 0.1, 0.6)
	_mat("cyan", Color(0.02, 0.2, 0.25), 0.4, 0.4, Color(0.0, 0.8, 1.0), 4.0)
	_mat("cyan_dim", Color(0.02, 0.15, 0.2), 0.4, 0.5, Color(0.0, 0.8, 1.0), 1.5)
	_mat("amber", Color(0.25, 0.15, 0.02), 0.4, 0.45, Color(1.0, 0.6, 0.0), 3.0)
	_mat("red", Color(0.2, 0.02, 0.03), 0.4, 0.45, Color(1.0, 0.1, 0.2), 3.5)
	_mat("sign_yellow", Color(0.75, 0.62, 0.05), 0.2, 0.6)
	_mat("grime", Color(0.13, 0.13, 0.12), 0.2, 0.95)
	_mat("rust", Color(0.28, 0.14, 0.07), 0.3, 0.9)
	_mat("tile", Color(0.17, 0.18, 0.19), 0.2, 0.8)
	_mat("hazard", Color(0.55, 0.45, 0.05), 0.3, 0.7)
	_mat("black_frame", Color(0.02, 0.022, 0.025), 0.35, 0.8)

# ---------------------------------------------------------------- primitives
func _box_mesh(s: Vector3) -> BoxMesh:
	var key := "%.3f_%.3f_%.3f" % [s.x, s.y, s.z]
	if not _box_cache.has(key):
		var m := BoxMesh.new()
		m.size = s
		_box_cache[key] = m
	return _box_cache[key]

func _cyl_mesh(r: float, h: float) -> CylinderMesh:
	var key := "%.3f_%.3f" % [r, h]
	if not _cyl_cache.has(key):
		var m := CylinderMesh.new()
		m.top_radius = r
		m.bottom_radius = r
		m.height = h
		m.radial_segments = 12
		_cyl_cache[key] = m
	return _cyl_cache[key]

func _box(parent: Node3D, n: String, pos: Vector3, size: Vector3, mat: String, rot_y: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = _box_mesh(size)
	mi.material_override = mats[mat]
	mi.position = pos
	if rot_y != 0.0:
		mi.rotation.y = rot_y
	parent.add_child(mi)
	return mi

func _cyl(parent: Node3D, n: String, pos: Vector3, r: float, h: float, mat: String, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = _cyl_mesh(r, h)
	mi.material_override = mats[mat]
	mi.position = pos
	mi.rotation = rot
	parent.add_child(mi)
	return mi

func _omni(parent: Node3D, n: String, pos: Vector3, color: Color, energy: float, rng: float, shadow: bool = false) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = n
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	l.shadow_enabled = shadow
	parent.add_child(l)
	return l

func _collider(parent: Node3D, n: String, pos: Vector3, size: Vector3) -> void:
	var body := parent.get_node_or_null(n) as StaticBody3D
	if body == null:
		body = StaticBody3D.new()
		body.name = n
		parent.add_child(body)
	var cs := CollisionShape3D.new()
	cs.name = "CS_%d" % (body.get_child_count() + 1)
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	cs.position = pos
	body.add_child(cs)

# ---------------------------------------------------------------- level
func _build_level_scene() -> void:
	var root := Node3D.new()
	root.name = "Level1"

	var we := WorldEnvironment.new()
	we.name = "WorldEnvironment"
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.008, 0.015, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.04, 0.055, 0.085)
	env.ambient_light_energy = 1.2
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = Color(0.01, 0.02, 0.05)
	env.fog_light_energy = 0.6
	env.fog_density = 0.03
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.9
	env.glow_bloom = 0.15
	we.environment = env
	root.add_child(we)

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color(0.55, 0.68, 0.85)
	sun.light_energy = 0.35
	sun.shadow_enabled = false
	sun.rotation_degrees = Vector3(-42, 35, 0)
	root.add_child(sun)

	var gen := Node3D.new()
	gen.name = "EIRA_Level1_Generated"
	root.add_child(gen)

	for z in ZONES:
		_build_zone(gen, z)

	_build_transitions(gen)
	_build_decor(gen)
	_build_neon(gen)
	_build_gameplay(root)

	var player_scene: PackedScene = load("res://scenes/Player.tscn")
	var player := player_scene.instantiate()
	player.name = "Player"
	player.set_scene_file_path("res://scenes/Player.tscn")
	player.position = Vector3(6.0, 0.05, 0.0)
	root.add_child(player)

	var nova_scene: PackedScene = load("res://scenes/Nova.tscn")
	var nova := nova_scene.instantiate()
	nova.name = "Nova"
	nova.set_scene_file_path("res://scenes/Nova.tscn")
	nova.position = Vector3(4.5, 0.0, -1.1)
	root.add_child(nova)

	_set_owner(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack failed %d" % err)
		return
	err = ResourceSaver.save(ps, "res://scenes/Level1.tscn")
	print("Level1 saved: ", err)

func _build_zone(parent: Node3D, z: Dictionary) -> void:
	var zn: String = z["name"]
	var x0: float = z["start"]
	var x1: float = z["end"]
	var hw: float = z["hw"]
	var length := x1 - x0
	var mid := (x0 + x1) * 0.5

	var zone := Node3D.new()
	zone.name = zn
	parent.add_child(zone)

	# shell
	_box(zone, "Floor", Vector3(mid, -0.2, 0), Vector3(length, 0.4, hw * 2.0), "dark")
	_box(zone, "Ceiling", Vector3(mid, CEIL_H + 0.25, 0), Vector3(length, 0.5, hw * 2.0), "dark")
	_box(zone, "Wall_L", Vector3(mid, CEIL_H * 0.5, -hw), Vector3(length, CEIL_H, WALL_T), "metal")
	_box(zone, "Wall_R", Vector3(mid, CEIL_H * 0.5, hw), Vector3(length, CEIL_H, WALL_T), "metal")

	_collider(zone, "Colliders", Vector3(mid, -0.2, 0), Vector3(length, 0.4, hw * 2.0))
	_collider(zone, "Colliders", Vector3(mid, CEIL_H * 0.5, -hw), Vector3(length, CEIL_H, WALL_T))
	_collider(zone, "Colliders", Vector3(mid, CEIL_H * 0.5, hw), Vector3(length, CEIL_H, WALL_T))
	_collider(zone, "Colliders", Vector3(mid, CEIL_H + 0.25, 0), Vector3(length, 0.5, hw * 2.0))

	# floor seams
	var seam_count := int(length / 10.0)
	for i in seam_count + 1:
		var sx := x0 + 2.5 + i * 10.0
		if sx > x1 - 1.0:
			continue
		_box(zone, "Seam_%d" % i, Vector3(sx, 0.005, 0), Vector3(0.12, 0.01, hw * 1.9), "metal_dark")

	match zn:
		"Zone1_Entry":
			_box(zone, "EndWall", Vector3(x0 + 0.25, CEIL_H * 0.5, 0), Vector3(0.5, CEIL_H, hw * 2.0), "metal")
			_collider(zone, "Colliders", Vector3(x0 + 0.25, CEIL_H * 0.5, 0), Vector3(0.5, CEIL_H, hw * 2.0))
			_box(zone, "EntryFrame_L", Vector3(0.6, CEIL_H * 0.5, -hw + 0.6), Vector3(2.0, CEIL_H, 1.2), "tech")
			_box(zone, "EntryFrame_R", Vector3(0.6, CEIL_H * 0.5, hw - 0.6), Vector3(2.0, CEIL_H, 1.2), "tech")
			_box(zone, "EntryHeader", Vector3(0.6, CEIL_H - 0.6, 0), Vector3(2.0, 1.2, hw * 2.0 - 2.4), "tech")
			var panel_x := 6.0
			while panel_x < x1:
				_box(zone, "WallPanel", Vector3(panel_x, 2.6, -hw + 0.35), Vector3(3.0, 2.2, 0.25), "tech")
				_box(zone, "WallPanel_Glow", Vector3(panel_x, 2.6, -hw + 0.5), Vector3(2.6, 0.12, 0.06), "cyan_dim")
				panel_x += 8.0
			_box(zone, "Crate_A", Vector3(12.5, 0.75, -6.5), Vector3(1.6, 1.5, 1.6), "metal_dark")
			_box(zone, "Crate_B", Vector3(14.4, 0.6, -6.0), Vector3(1.2, 1.2, 1.2), "grime")
			_cyl(zone, "Barrel", Vector3(16.0, 0.55, 5.2), 0.45, 1.1, "rust")
		"Zone2_Hall":
			var px := 26.0
			while px < x1 - 2.0:
				_cyl(zone, "Pipe", Vector3(px, 6.6, hw - 0.6), 0.16, 12.0, "metal", Vector3(0, 0, PI * 0.5))
				_cyl(zone, "PipeSub", Vector3(px, 6.3, hw - 0.85), 0.08, 12.0, "metal_dark", Vector3(0, 0, PI * 0.5))
				_box(zone, "Beam", Vector3(px, CEIL_H - 0.4, 0), Vector3(1.5, 0.8, hw * 2.0), "metal_dark")
				_box(zone, "PipeBracket", Vector3(px, 6.95, hw - 0.6), Vector3(0.4, 0.3, 0.6), "metal_dark")
				px += 12.0
			var cable_x := 30.0
			while cable_x < x1 - 4.0:
				_box(zone, "CableTray", Vector3(cable_x, CEIL_H - 0.7, -hw + 1.2), Vector3(4.0, 0.2, 0.6), "metal_dark")
				_cyl(zone, "Cable", Vector3(cable_x, CEIL_H - 0.85, -hw + 1.2), 0.07, 4.0, "rubber", Vector3(0, 0, PI * 0.5))
				cable_x += 9.0
		"Zone3_CombatHub":
			_box(zone, "Cover_A", Vector3(mid - 8.0, 1.25, 4.0), Vector3(4.0, 2.5, 2.0), "metal_dark")
			_box(zone, "Cover_B", Vector3(mid + 8.0, 1.25, -4.0), Vector3(4.0, 2.5, 2.0), "metal_dark")
			_box(zone, "CoreBase", Vector3(mid, 0.5, 0), Vector3(3.0, 1.0, 3.0), "metal")
			_box(zone, "CoreMain", Vector3(mid, 3.0, 0), Vector3(1.5, 4.0, 1.5), "tech")
			_box(zone, "CoreRing", Vector3(mid, 4.6, 0), Vector3(2.4, 0.5, 2.4), "metal")
			_box(zone, "CoreGlow", Vector3(mid, 2.0, 0.8), Vector3(1.1, 2.6, 0.1), "cyan")
			_collider(zone, "Colliders", Vector3(mid - 8.0, 1.25, 4.0), Vector3(4.0, 2.5, 2.0))
			_collider(zone, "Colliders", Vector3(mid + 8.0, 1.25, -4.0), Vector3(4.0, 2.5, 2.0))
			_collider(zone, "Colliders", Vector3(mid, 2.5, 0), Vector3(2.0, 5.0, 2.0))
			var ws := 62.0
			while ws < x1 - 2.0:
				_box(zone, "WarnStrip", Vector3(ws, 0.01, 0), Vector3(1.6, 0.02, hw * 1.6), "hazard")
				ws += 15.0
		"Zone4_BossArena":
			var bx := 110.0
			while bx < x1 - 2.0:
				_box(zone, "Pillar_L", Vector3(bx, CEIL_H * 0.5, -hw + 3.0), Vector3(3.0, CEIL_H, 3.0), "dark")
				_box(zone, "Pillar_R", Vector3(bx, CEIL_H * 0.5, hw - 3.0), Vector3(3.0, CEIL_H, 3.0), "dark")
				_box(zone, "PillarLight_L", Vector3(bx, CEIL_H - 0.5, -hw + 3.0), Vector3(3.1, 0.25, 3.1), "red")
				_box(zone, "PillarLight_R", Vector3(bx, CEIL_H - 0.5, hw - 3.0), Vector3(3.1, 0.25, 3.1), "red")
				_collider(zone, "Colliders", Vector3(bx, CEIL_H * 0.5, -hw + 3.0), Vector3(3.0, CEIL_H, 3.0))
				_collider(zone, "Colliders", Vector3(bx, CEIL_H * 0.5, hw - 3.0), Vector3(3.0, CEIL_H, 3.0))
				bx += 25.0
			_box(zone, "ArenaRing", Vector3(120.0, 0.02, 0), Vector3(28.0, 0.04, 28.0), "metal_dark")
			_box(zone, "ArenaRingInner", Vector3(120.0, 0.03, 0), Vector3(20.0, 0.05, 20.0), "graphite")
			_box(zone, "ArenaCore", Vector3(120.0, 0.8, 0), Vector3(2.4, 1.6, 2.4), "tech")
		"Zone5_Exit":
			var sx2 := 145.0
			while sx2 < x1 - 1.0:
				_box(zone, "Support_L", Vector3(sx2, CEIL_H * 0.5, -hw + 0.5), Vector3(1.0, CEIL_H, 1.0), "metal")
				_box(zone, "Support_R", Vector3(sx2, CEIL_H * 0.5, hw - 0.5), Vector3(1.0, CEIL_H, 1.0), "metal")
				_collider(zone, "Colliders", Vector3(sx2, CEIL_H * 0.5, -hw + 0.5), Vector3(1.0, CEIL_H, 1.0))
				_collider(zone, "Colliders", Vector3(sx2, CEIL_H * 0.5, hw - 0.5), Vector3(1.0, CEIL_H, 1.0))
				sx2 += 10.0
			_box(zone, "ExitBase", Vector3(170.0, 0.2, 0), Vector3(2.0, 0.4, hw * 2.0), "metal")
			_box(zone, "ExitCeil", Vector3(170.0, CEIL_H - 0.2, 0), Vector3(2.0, 0.4, hw * 2.0), "metal")
			_box(zone, "ExitFrame_L", Vector3(170.0, CEIL_H * 0.5, -hw + 0.5), Vector3(2.0, CEIL_H, 1.0), "cyan")
			_box(zone, "ExitFrame_R", Vector3(170.0, CEIL_H * 0.5, hw - 0.5), Vector3(2.0, CEIL_H, 1.0), "cyan")
			_box(zone, "ExitDoor", Vector3(170.2, 3.2, 0), Vector3(0.25, 5.6, hw * 2.0 - 2.0), "cyan")
			_box(zone, "ExitSign", Vector3(168.8, 5.6, 0), Vector3(0.2, 0.8, 3.0), "cyan")
			_collider(zone, "Colliders", Vector3(170.2, 3.2, 0), Vector3(0.3, 5.6, hw * 2.0 - 2.0))
			var gs := 142.0
			while gs < 168.0:
				_box(zone, "GuideStrip", Vector3(gs, 0.01, 0), Vector3(1.2, 0.02, 2.0), "cyan_dim")
				gs += 5.0

func _build_transitions(parent: Node3D) -> void:
	var tr := Node3D.new()
	tr.name = "Zone_Transitions"
	parent.add_child(tr)
	var bounds := [20.0, 60.0, 100.0, 140.0]
	for i in bounds.size():
		var bx: float = bounds[i]
		var hw := 10.0
		if bx == 60.0:
			hw = 15.0
		elif bx == 100.0:
			hw = 20.0
		var accent := "cyan"
		if i == 2:
			accent = "red"
		elif i == 1:
			accent = "amber"
		_box(tr, "Bulkhead_L", Vector3(bx, CEIL_H * 0.5, -hw + 0.7), Vector3(1.6, CEIL_H, 1.4), "metal_dark")
		_box(tr, "Bulkhead_R", Vector3(bx, CEIL_H * 0.5, hw - 0.7), Vector3(1.6, CEIL_H, 1.4), "metal_dark")
		_box(tr, "Bulkhead_Header", Vector3(bx, CEIL_H - 0.9, 0), Vector3(1.6, 1.8, hw * 2.0 - 1.4), "metal_dark")
		_box(tr, "Bulkhead_Glow_L", Vector3(bx - 0.9, 3.0, -hw + 0.7), Vector3(0.12, 4.0, 0.9), accent)
		_box(tr, "Bulkhead_Glow_R", Vector3(bx - 0.9, 3.0, hw - 0.7), Vector3(0.12, 4.0, 0.9), accent)
		_box(tr, "HazardStrip", Vector3(bx, 0.01, 0), Vector3(1.4, 0.02, hw * 2.0 - 1.0), "hazard")
		_box(tr, "HangingSign", Vector3(bx + 0.1, CEIL_H - 2.6, 0), Vector3(0.15, 0.7, 2.6), accent)
		_box(tr, "SignRod", Vector3(bx + 0.1, CEIL_H - 1.9, 0), Vector3(0.08, 0.8, 0.08), "metal_dark")
		_omni(tr, "ThresholdLight", Vector3(bx - 1.5, 4.5, 0), Color(0.0, 0.8, 1.0) if i != 2 else Color(1.0, 0.1, 0.2), 3.0, 14.0)

func _build_decor(parent: Node3D) -> void:
	var decor := Node3D.new()
	decor.name = "Lab_Detailed_Decor"
	parent.add_child(decor)

	for zi in ZONES.size():
		var z: Dictionary = ZONES[zi]
		var zn: String = z["name"]
		var x0: float = z["start"]
		var x1: float = z["end"]
		var hw: float = z["hw"]
		var zone_decor := Node3D.new()
		zone_decor.name = "Zone_Z%d_%s" % [zi + 1, zn]
		decor.add_child(zone_decor)

		for side: float in [-1.0, 1.0]:
			var wall := Node3D.new()
			wall.name = "Wall_%s" % ("L" if side < 0.0 else "R")
			zone_decor.add_child(wall)
			var wz := side * (hw - 0.25)
			var length := x1 - x0
			var mid := (x0 + x1) * 0.5

			# wall plinth / panel / cornice stack
			_box(wall, "Plinth", Vector3(mid, 0.34, wz), Vector3(length, 0.68, 0.34), "steel")
			_box(wall, "PlinthInset", Vector3(mid, 0.34, wz - side * 0.19), Vector3(length, 0.44, 0.06), "graphite")
			_box(wall, "WallPanelUpper", Vector3(mid, 3.35, wz), Vector3(length, 5.14, 0.06), "graphite")
			_box(wall, "Cornice", Vector3(mid, 5.74, wz), Vector3(length, 0.28, 0.24), "steel")
			_box(wall, "CorniceLip", Vector3(mid, 5.92, wz), Vector3(length, 0.08, 0.32), "metal")

			# ribs
			var rx := x0 + 2.1
			while rx < x1 - 1.0:
				_box(wall, "Rib", Vector3(rx, 2.95, wz - side * 0.12), Vector3(0.16, 5.35, 0.18), "metal_dark")
				_box(wall, "RibAccent", Vector3(rx, 5.2, wz - side * 0.22), Vector3(0.1, 0.5, 0.06), "cyan_dim")
				rx += 4.2

			# modules
			var usable_start := x0 + (1.6 if zi < 2 else 0.9)
			var usable_end := x1 - (1.6 if zi >= 3 else 0.9)
			var usable := usable_end - usable_start
			var count := int(ceil((usable + 0.32) / 4.32))
			if count < 1:
				count = 1
			var w := clampf((usable - 0.32 * (count - 1)) / float(count), 2.2, 4.0)
			var cx := usable_start
			for mi in count:
				var mod := Node3D.new()
				mod.name = "Module_%02d" % mi
				wall.add_child(mod)
				var mz := wz - side * 0.2
				_box(mod, "FrameTop", Vector3(cx + w * 0.5, 0.55 + 5.8 - 0.16, mz), Vector3(w, 0.32, 0.36), "black_frame")
				_box(mod, "FrameBottom", Vector3(cx + w * 0.5, 0.55 + 0.16, mz), Vector3(w, 0.32, 0.36), "black_frame")
				_box(mod, "FrameLeft", Vector3(cx + 0.16, 0.55 + 2.9, mz), Vector3(0.32, 5.8, 0.36), "black_frame")
				_box(mod, "FrameRight", Vector3(cx + w - 0.16, 0.55 + 2.9, mz), Vector3(0.32, 5.8, 0.36), "black_frame")
				_box(mod, "Back", Vector3(cx + w * 0.5, 0.55 + 2.9, mz + side * 0.14), Vector3(w - 0.6, 5.2, 0.06), "graphite")
				_build_module_content(mod, cx + w * 0.5, mz, side, w, zi, mi)
				cx += w + 0.32

			# floor threshold + hazard lines
			_box(wall, "Threshold", Vector3(mid, 0.01, wz - side * 0.35), Vector3(length, 0.02, 0.7), "tile")
			var hx := x0 + 3.0
			while hx < x1 - 1.0:
				_box(wall, "HazardLine", Vector3(hx, 0.02, wz - side * 0.7), Vector3(1.0, 0.02, 0.25), "hazard")
				hx += 6.0

		# ceiling dressing
		var ceil_decor := Node3D.new()
		ceil_decor.name = "Ceiling"
		zone_decor.add_child(ceil_decor)
		var bx2 := x0 + 3.0
		while bx2 < x1 - 2.0:
			_box(ceil_decor, "CeilBeam", Vector3(bx2, CEIL_H - 0.35, 0), Vector3(0.6, 0.5, hw * 2.0 - 1.0), "metal_dark")
			bx2 += 5.0

		# floor dressing
		var floor_decor := Node3D.new()
		floor_decor.name = "FloorDressing"
		zone_decor.add_child(floor_decor)
		var dx := x0 + 5.0
		while dx < x1 - 3.0:
			if _rng.randf() < 0.55:
				var dw := _rng.randf_range(1.2, 2.4)
				_box(floor_decor, "Drain", Vector3(dx, 0.02, _rng.randf_range(-hw + 2.0, hw - 2.0)), Vector3(dw, 0.04, dw), "metal_dark")
			dx += 7.0

		# props
		var props := Node3D.new()
		props.name = "Props"
		zone_decor.add_child(props)
		var nprops := 3 + zi
		for p in nprops:
			var pxp := _rng.randf_range(x0 + 3.0, x1 - 3.0)
			var pzp := _rng.randf_range(-(hw - 2.5), hw - 2.5)
			var pick := _rng.randi_range(0, 2)
			match pick:
				0:
					_box(props, "Crate", Vector3(pxp, 0.5, pzp), Vector3(1.0, 1.0, 1.0), "grime")
				1:
					_cyl(props, "Barrel", Vector3(pxp, 0.55, pzp), 0.45, 1.1, "rust")
				2:
					_box(props, "Console", Vector3(pxp, 0.6, pzp), Vector3(1.4, 1.2, 0.8), "metal_dark")
					_box(props, "ConsoleScreen", Vector3(pxp, 1.25, pzp), Vector3(1.0, 0.08, 0.5), "cyan_dim")

func _build_module_content(mod: Node3D, cx: float, mz: float, side: float, w: float, zi: int, mi: int) -> void:
	var kind := (zi * 3 + mi) % 5
	var zf := mz - side * 0.12
	match kind:
		0:
			_box(mod, "Vents", Vector3(cx, 0.55 + 3.4, zf), Vector3(w - 1.2, 1.6, 0.16), "metal")
			for i in 4:
				_box(mod, "Slat", Vector3(cx, 0.55 + 2.9 + i * 0.35, zf - side * 0.1), Vector3(w - 1.4, 0.14, 0.08), "metal_dark")
		1:
			_box(mod, "Screen", Vector3(cx, 0.55 + 3.6, zf), Vector3(w - 1.4, 1.2, 0.1), "graphite")
			_box(mod, "ScreenGlow", Vector3(cx, 0.55 + 3.6, zf - side * 0.07), Vector3(w - 1.7, 0.9, 0.04), "cyan_dim")
			_box(mod, "Console2", Vector3(cx, 0.55 + 1.4, zf), Vector3(w - 1.6, 1.6, 0.3), "metal_dark")
		2:
			_cyl(mod, "PipeA", Vector3(cx - w * 0.25, 0.55 + 2.6, zf), 0.12, 4.4, "steel")
			_cyl(mod, "PipeB", Vector3(cx + w * 0.25, 0.55 + 2.6, zf), 0.12, 4.4, "steel")
			_box(mod, "Valve", Vector3(cx, 0.55 + 1.4, zf - side * 0.08), Vector3(w - 1.4, 0.3, 0.2), "amber")
		3:
			_box(mod, "Cabinet", Vector3(cx, 0.55 + 1.6, zf), Vector3(w - 1.3, 2.6, 0.4), "steel")
			for i in 3:
				_box(mod, "Drawer", Vector3(cx, 0.55 + 0.7 + i * 0.8, zf - side * 0.22), Vector3(w - 1.7, 0.5, 0.06), "metal_dark")
			_box(mod, "CabinetLamp", Vector3(cx, 0.55 + 3.2, zf - side * 0.18), Vector3(w - 2.0, 0.1, 0.06), "cyan_dim")
		4:
			_box(mod, "Tank", Vector3(cx, 0.55 + 1.3, zf), Vector3(w - 1.6, 2.0, 0.5), "graphite")
			_box(mod, "TankGlow", Vector3(cx, 0.55 + 1.6, zf - side * 0.27), Vector3(0.25, 1.2, 0.05), "amber")
			_box(mod, "TopCap", Vector3(cx, 0.55 + 2.5, zf), Vector3(w - 1.4, 0.2, 0.6), "metal")

func _build_neon(parent: Node3D) -> void:
	var lights := Node3D.new()
	lights.name = "Visual_Decor_Lights"
	parent.add_child(lights)

	for zi in ZONES.size():
		var z: Dictionary = ZONES[zi]
		var x0: float = z["start"]
		var x1: float = z["end"]
		var hw: float = z["hw"]
		var zone_lights := Node3D.new()
		zone_lights.name = "Lights_Z%d" % (zi + 1)
		lights.add_child(zone_lights)

		var accent := "cyan"
		var accent_color := Color(0.0, 0.8, 1.0)
		if zi == 1:
			accent = "amber"
			accent_color = Color(1.0, 0.6, 0.0)
		elif zi == 3:
			accent = "red"
			accent_color = Color(1.0, 0.1, 0.2)

		var lx := x0 + 4.0
		while lx < x1 - 2.0:
			_box(zone_lights, "NeonStrip_L", Vector3(lx, 5.0, -(hw - 0.45)), Vector3(3.0, 0.12, 0.08), accent)
			_box(zone_lights, "NeonStrip_R", Vector3(lx, 4.4, hw - 0.45), Vector3(2.2, 0.1, 0.08), "cyan_dim")
			_box(zone_lights, "FloorStrip_L", Vector3(lx, 0.03, -(hw - 1.1)), Vector3(3.4, 0.04, 0.12), accent)
			_box(zone_lights, "FloorStrip_R", Vector3(lx, 0.03, hw - 1.1), Vector3(3.4, 0.04, 0.12), "cyan_dim")
			_box(zone_lights, "CeilLamp", Vector3(lx, CEIL_H - 0.7, 0), Vector3(2.6, 0.12, 0.5), "white")
			_omni(zone_lights, "CeilLight", Vector3(lx, CEIL_H - 1.2, 0), Color(0.75, 0.85, 1.0), 5.0, 15.0)
			_omni(zone_lights, "AccentLight", Vector3(lx, 3.4, -(hw - 1.2)), accent_color, 3.0, 10.0)
			_omni(zone_lights, "FloorFill", Vector3(lx, 0.8, hw - 1.6), Color(0.6, 0.75, 1.0), 1.6, 8.0)
			lx += 8.0

	# forest transition marker
	var forest := Node3D.new()
	forest.name = "Lab_Forest_Transition"
	parent.add_child(forest)
	_box(forest, "ForestFloor", Vector3(175.0, -0.6, 0), Vector3(12.0, 0.4, 40.0), "grime")
	_box(forest, "TransitionLight", Vector3(172.5, -0.3, 0), Vector3(0.5, 0.6, 0.5), "amber")
	_omni(forest, "TransitionGlow", Vector3(172.5, 0.6, 0), Color(1.0, 0.6, 0.0), 2.0, 10.0)

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

	_build_files(gameplay)
	_build_terminals(gameplay)
	_build_barriers(gameplay)
	_build_pickups(gameplay)
	_build_spawn_points(gameplay)
	_build_boss_marker(gameplay)
	_build_level_exit(gameplay)
	_build_director(gameplay)

	var hud_scene: PackedScene = load("res://scenes/HUD.tscn")
	var hud := hud_scene.instantiate()
	hud.name = "HUD"
	hud.set_scene_file_path("res://scenes/HUD.tscn")
	root.add_child(hud)

func _build_files(parent: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "DataFiles"
	parent.add_child(holder)
	for f in FILES:
		var code: String = f["code"]
		var pos: Vector3 = f["pos"]
		var node: Node = _instance("res://scenes/DataFile.tscn", holder, "File_%s" % code, pos)
		node.set("code", code)

func _build_terminals(parent: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "Terminals"
	parent.add_child(holder)
	for t in TERMINALS:
		var idx: int = t["index"]
		var pos: Vector3 = t["pos"]
		var node: Node = _instance("res://scenes/Terminal.tscn", holder, "Terminal_%02d" % idx, pos, PI * 0.5)
		node.set("index", idx)
		node.set("display_name", String(t["name"]))
		var codes: Array[String] = []
		for c in t["codes"]:
			codes.append(String(c))
		node.set("required_codes", codes)

func _build_barriers(parent: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "Barriers"
	parent.add_child(holder)
	for b in BARRIERS:
		var bx: float = b["x"]
		var hw: float = b["hw"]
		var barrier := StaticBody3D.new()
		barrier.name = "Barrier_%d" % int(bx)
		barrier.set_script(load("res://scripts/Barrier.gd"))
		barrier.set("required_resolutions", b["res"])
		barrier.set("requires_boss", b["boss"])
		barrier.add_to_group("barrier")
		holder.add_child(barrier)

		var panel := Node3D.new()
		panel.name = "Panel"
		barrier.add_child(panel)

		_box(panel, "Field", Vector3(0.35, CEIL_H - 0.4, hw * 2.0 - 0.6), Vector3(bx, (CEIL_H - 0.4) * 0.5, 0), "cyan")
		_box(panel, "FrameTop", Vector3(0.7, 0.5, hw * 2.0), Vector3(bx, CEIL_H - 0.25, 0), "metal_dark")
		_box(panel, "FrameBottom", Vector3(0.7, 0.5, hw * 2.0), Vector3(bx, 0.25, 0), "metal_dark")
		var light := OmniLight3D.new()
		light.name = "BarrierLight"
		light.light_color = Color(0.0, 0.8, 1.0)
		light.light_energy = 3.0
		light.omni_range = 12.0
		light.position = Vector3(bx, 3.0, 0)
		panel.add_child(light)

		var cs := CollisionShape3D.new()
		cs.name = "CollisionShape3D"
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.6, CEIL_H - 0.4, hw * 2.0 - 0.6)
		cs.shape = bs
		cs.position = Vector3(bx, (CEIL_H - 0.4) * 0.5, 0)
		barrier.add_child(cs)

func _build_pickups(parent: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "Pickups"
	parent.add_child(holder)
	for p in HEALTH_PICKUPS:
		var node: Node = _instance("res://scenes/Pickup.tscn", holder, "Health_%d" % int(p.x), p)
		node.set("kind", 0)
		node.set("amount", 30)
	for p in AMMO_PICKUPS:
		var node: Node = _instance("res://scenes/Pickup.tscn", holder, "Ammo_%d" % int(p.x), p)
		node.set("kind", 1)
		node.set("amount", 24)

func _build_spawn_points(parent: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "SpawnPoints"
	parent.add_child(holder)
	for i in SPAWN_POINTS.size():
		var sp := Node3D.new()
		sp.name = "Spawn_%02d" % i
		sp.position = SPAWN_POINTS[i]
		sp.add_to_group("spawn_point")
		holder.add_child(sp)

func _build_boss_marker(parent: Node3D) -> void:
	var marker := Node3D.new()
	marker.name = "BossSpawn"
	marker.position = Vector3(124.0, 0.0, 0.0)
	marker.add_to_group("boss_spawn")
	parent.add_child(marker)
	_box(parent, "BossPad", Vector3(7.0, 0.06, 7.0), Vector3(124.0, 0.03, 0.0), "hazard")

func _build_level_exit(parent: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "LevelExit"
	parent.add_child(holder)

	var exit := Area3D.new()
	exit.name = "ExitPortal"
	exit.set_script(load("res://scripts/LevelExit.gd"))
	exit.set("next_scene", "res://scenes/Level2.tscn")
	exit.set("requires_boss", true)
	exit.set("enabled", false)
	exit.position = Vector3(167.5, 0.0, 0.0)
	holder.add_child(exit)

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var bs := BoxShape3D.new()
	bs.size = Vector3(2.0, 5.0, 6.0)
	col.shape = bs
	col.position = Vector3(0, 2.5, 0)
	exit.add_child(col)

	var visual := Node3D.new()
	visual.name = "Visual"
	exit.add_child(visual)
	_box(visual, "Frame", Vector3(0.3, 5.0, 6.4), Vector3.ZERO, "metal_dark")
	_box(visual, "Glow", Vector3(0.12, 4.4, 5.6), Vector3(-0.15, 0.0, 0.0), "cyan")
	var light := OmniLight3D.new()
	light.name = "ExitLight"
	light.light_color = Color(0.0, 0.85, 1.0)
	light.light_energy = 3.0
	light.omni_range = 14.0
	light.position = Vector3(0, 2.4, 0)
	visual.add_child(light)

	var label := Label3D.new()
	label.name = "Label"
	label.text = "SALIDA"
	label.font_size = 56
	label.pixel_size = 0.006
	label.position = Vector3(-0.4, 3.1, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(0.4, 1.0, 0.8)
	exit.add_child(label)

func _build_director(parent: Node3D) -> void:
	var director := Node.new()
	director.name = "LevelDirector"
	director.set_script(load("res://scripts/LevelDirector.gd"))
	director.set("total_resolutions", TERMINALS.size())
	director.set("combat_after", 3)
	director.set("android_scene", load("res://scenes/Android.tscn"))
	director.set("boss_scene", load("res://scenes/AnalyticalMachine.tscn"))
	director.set("projectile_scene", load("res://scenes/Projectile.tscn"))
	parent.add_child(director)

# ---------------------------------------------------------------- characters
func _build_player_scene() -> void:
	var root := CharacterBody3D.new()
	root.name = "Player"
	root.set_script(load("res://scripts/Player.gd"))

	var col := CollisionShape3D.new()
	col.name = "CollisionShape3D"
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.7
	col.shape = cap
	col.position = Vector3(0, 0.85, 0)
	root.add_child(col)

	var visual := Node3D.new()
	visual.name = "Visual"
	visual.rotation.y = PI * 0.5
	root.add_child(visual)

	var eira: PackedScene = load("res://assets/characters/eira.glb")
	var inst := eira.instantiate()
	inst.name = "Eira"
	inst.set_scene_file_path("res://assets/characters/eira.glb")
	visual.add_child(inst)

	var pivot := Node3D.new()
	pivot.name = "CameraPivot"
	pivot.position = Vector3(0, 1.55, 0)
	pivot.rotation.y = -PI * 0.5
	root.add_child(pivot)

	var cam := Camera3D.new()
	cam.name = "Camera3D"
	cam.position = Vector3(0, 0, 4.2)
	cam.rotation.x = -0.12
	cam.fov = 75.0
	cam.far = 400.0
	pivot.add_child(cam)

	_build_weapon(cam)

	root.collision_layer = 2
	root.collision_mask = 1

	_set_owner(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	var err := ResourceSaver.save(ps, "res://scenes/Player.tscn")
	print("Player saved: ", err)

func _build_weapon(cam: Camera3D) -> void:
	var weapon := Node3D.new()
	weapon.name = "Weapon"
	weapon.set_script(load("res://scripts/Weapon.gd"))
	cam.add_child(weapon)

	var gun := Node3D.new()
	gun.name = "GunRoot"
	weapon.add_child(gun)

	var gun_metal := StandardMaterial3D.new()
	gun_metal.albedo_color = Color(0.10, 0.11, 0.13)
	gun_metal.metallic = 0.9
	gun_metal.roughness = 0.35

	var slide := _box(gun, "Slide", Vector3(0.09, 0.11, 0.42), Vector3(0, 0.04, -0.08), "black_frame")
	slide.material_override = gun_metal
	_box(gun, "GlowStrip", Vector3(0.03, 0.02, 0.18), Vector3(0.046, 0.05, -0.08), "cyan")
	var grip := _box(gun, "Grip", Vector3(0.08, 0.24, 0.13), Vector3(0, -0.14, 0.06), "metal_dark")
	grip.material_override = gun_metal
	_box(gun, "Trigger", Vector3(0.05, 0.07, 0.05), Vector3(0, -0.06, -0.02), "metal_dark")
	_box(gun, "Sight", Vector3(0.02, 0.035, 0.05), Vector3(0, 0.115, -0.2), "cyan")
	var barrel := _cyl(gun, "Barrel", Vector3(0, 0.04, -0.32), 0.028, 0.16, "steel", Vector3(PI * 0.5, 0, 0))
	barrel.material_override = gun_metal

	var muzzle := Node3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0, 0.04, -0.42)
	gun.add_child(muzzle)

	var flash_light := OmniLight3D.new()
	flash_light.name = "FlashLight"
	flash_light.light_color = Color(1.0, 0.85, 0.5)
	flash_light.light_energy = 0.0
	flash_light.omni_range = 9.0
	muzzle.add_child(flash_light)

	var flash_mesh := MeshInstance3D.new()
	flash_mesh.name = "FlashMesh"
	var fm := SphereMesh.new()
	fm.radius = 0.09
	fm.height = 0.18
	fm.radial_segments = 8
	fm.rings = 4
	flash_mesh.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(1.0, 0.9, 0.6)
	fmat.emission_enabled = true
	fmat.emission = Color(1.0, 0.8, 0.4)
	fmat.emission_energy_multiplier = 8.0
	fmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	flash_mesh.material_override = fmat
	flash_mesh.visible = false
	muzzle.add_child(flash_mesh)

	var tracer_root := Node3D.new()
	tracer_root.name = "Tracers"
	weapon.add_child(tracer_root)
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(1.0, 0.9, 0.5, 0.9)
	tmat.emission_enabled = true
	tmat.emission = Color(1.0, 0.8, 0.35)
	tmat.emission_energy_multiplier = 6.0
	tmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 4:
		var tracer := MeshInstance3D.new()
		tracer.name = "Tracer_%d" % i
		var bm := BoxMesh.new()
		bm.size = Vector3(0.04, 0.04, 1.0)
		tracer.mesh = bm
		tracer.material_override = tmat
		tracer.visible = false
		tracer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tracer_root.add_child(tracer)

	var impact_root := Node3D.new()
	impact_root.name = "Impacts"
	weapon.add_child(impact_root)
	var imat := StandardMaterial3D.new()
	imat.albedo_color = Color(1.0, 0.6, 0.25, 0.9)
	imat.emission_enabled = true
	imat.emission = Color(1.0, 0.5, 0.15)
	imat.emission_energy_multiplier = 5.0
	imat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	imat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for i in 4:
		var impact := MeshInstance3D.new()
		impact.name = "Impact_%d" % i
		var sm := SphereMesh.new()
		sm.radius = 0.1
		sm.height = 0.2
		sm.radial_segments = 8
		sm.rings = 4
		impact.mesh = sm
		impact.material_override = imat
		impact.visible = false
		impact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		impact_root.add_child(impact)

func _build_nova_scene() -> void:
	var root := Node3D.new()
	root.name = "Nova"
	root.set_script(load("res://scripts/NovaFollow.gd"))

	var visual := Node3D.new()
	visual.name = "Visual"
	root.add_child(visual)

	var nova: PackedScene = load("res://assets/characters/nova.glb")
	var inst := nova.instantiate()
	inst.name = "Nova"
	inst.set_scene_file_path("res://assets/characters/nova.glb")
	visual.add_child(inst)

	_set_owner(root, root)
	var ps := PackedScene.new()
	ps.pack(root)
	var err := ResourceSaver.save(ps, "res://scenes/Nova.tscn")
	print("Nova saved: ", err)

func _set_owner(node: Node, owner_node: Node) -> void:
	for c in node.get_children():
		c.owner = owner_node
		if c.scene_file_path == "":
			_set_owner(c, owner_node)
