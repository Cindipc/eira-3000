extends RefCounted

## Constructor del Nivel 3 "La ultima guerra".
##
## Reutiliza el escenario de ciudad del Nivel 2 (res://scenes/Level2.tscn):
## se conserva la ciudad, la calle, las props, el jugador, Nova y el HUD, y se
## sustituye el gameplay del nivel 2 por el del Nucleo Central.
##
## El interior del Nucleo se construye en la misma escena, desplazado a
## x = 400 para no chocar con la geometria de la ciudad (el FBX tiene un
## "ocean" de 3200 x 800 m a y = -0.9 que ocupa todo el mapa).

const LEVEL2_PATH := "res://scenes/Level2.tscn"
const OUT_PATH := "res://scenes/Level3.tscn"

const INTERIOR_ORIGIN := Vector3(400.0, 0.0, 0.0)
const INTERIOR_LEN := 126.0
const INTERIOR_HALF_Z := 12.0
const INTERIOR_HEIGHT := 7.0

const DOOR_X := 44.0
const DOOR_Z := 0.0

const ARENA_X := 74.0
const CORE_X := 121.0

const ANDROID_SCENE := "res://scenes/Android.tscn"
const PROJECTILE_SCENE := "res://scenes/Projectile.tscn"
const ROBOT_SCENE := "res://assets/characters/robot.glb"
const KAEL_MODEL := "res://assets/characters/kael.fbx"

var mats := {}
var _box_cache := {}

# ------------------------------------------------------------------ helpers
func _mat(key: String, albedo: Color, metallic := 0.6, roughness := 0.4, emission: Color = Color(0, 0, 0), energy := 0.0) -> StandardMaterial3D:
	if mats.has(key):
		return mats[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	mats[key] = m
	return m

func _box_mesh(s: Vector3) -> BoxMesh:
	var key := "%.2f_%.2f_%.2f" % [s.x, s.y, s.z]
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

func _cyl(parent: Node3D, n: String, pos: Vector3, radius: float, height: float, mat: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 20
	mi.mesh = cm
	mi.material_override = mats[mat]
	mi.position = pos
	parent.add_child(mi)
	return mi

func _sphere(parent: Node3D, n: String, pos: Vector3, radius: float, mat: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	mi.mesh = sm
	mi.material_override = mats[mat]
	mi.position = pos
	parent.add_child(mi)
	return mi

func _torus(parent: Node3D, n: String, pos: Vector3, inner: float, outer: float, mat: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	var tm := TorusMesh.new()
	tm.inner_radius = inner
	tm.outer_radius = outer
	mi.mesh = tm
	mi.material_override = mats[mat]
	mi.position = pos
	parent.add_child(mi)
	return mi

func _label(parent: Node3D, n: String, text: String, pos: Vector3, size := 42, color := Color(0.85, 0.95, 1.0)) -> Label3D:
	var l := Label3D.new()
	l.name = n
	l.text = text
	l.font_size = size
	l.pixel_size = 0.005
	l.modulate = color
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.position = pos
	parent.add_child(l)
	return l

func _light(parent: Node3D, n: String, pos: Vector3, color: Color, energy: float, rng: float) -> OmniLight3D:
	var l := OmniLight3D.new()
	l.name = n
	l.position = pos
	l.light_color = color
	l.light_energy = energy
	l.omni_range = rng
	parent.add_child(l)
	return l

func _solid(parent: Node3D, n: String, pos: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = n
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = pos
	parent.add_child(body)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var bs := BoxShape3D.new()
	bs.size = size
	cs.shape = bs
	body.add_child(cs)
	return body

func _instance(path: String, parent: Node, n: String, pos: Vector3, rot_y := 0.0) -> Node:
	var ps := load(path) as PackedScene
	if ps == null:
		push_error("no se pudo cargar " + path)
		return null
	var node := ps.instantiate()
	node.name = n
	node.set_scene_file_path(path)
	node.position = pos
	node.rotation.y = rot_y
	parent.add_child(node)
	return node

func _interactable(parent: Node3D, n: String, script_path: String, pos: Vector3, radius := 2.2) -> Node:
	var area := Area3D.new()
	area.name = n
	area.set_script(load(script_path))
	area.collision_layer = 16
	area.collision_mask = 2
	area.position = pos
	parent.add_child(area)
	var cs := CollisionShape3D.new()
	cs.name = "Shape"
	var shape := CylinderShape3D.new()
	shape.radius = radius
	shape.height = 3.2
	cs.shape = shape
	cs.position = Vector3(0, 1.6, 0)
	area.add_child(cs)
	return area

# ------------------------------------------------------------------ build
func build() -> void:
	_build_materials()
	var l2 := load(LEVEL2_PATH) as PackedScene
	if l2 == null:
		push_error("no se pudo cargar " + LEVEL2_PATH)
		return
	var root := l2.instantiate() as Node3D
	root.name = "Level3"
	root.scene_file_path = ""

	_remove_l2_gameplay(root)
	_tune_environment(root)
	_move_player(root)

	var interior := _build_interior(root)
	_build_nucleo_exterior(root, interior)
	_build_layers(root)
	_build_director(root, interior)

	_set_owner(root, root)
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err != OK:
		push_error("pack failed %d" % err)
		return
	err = ResourceSaver.save(ps, OUT_PATH)
	print("Level3 saved: ", err)

func _remove_l2_gameplay(root: Node3D) -> void:
	var gp := root.get_node_or_null("Gameplay")
	if gp:
		root.remove_child(gp)
		gp.free()
		print("gameplay del nivel 2 retirado")

func _tune_environment(root: Node3D) -> void:
	var we := root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we == null:
		return
	var env := we.environment
	if env == null:
		return
	env.fog_density = 0.012
	env.ambient_light_color = Color(0.06, 0.07, 0.11)
	env.ambient_light_energy = 1.15
	env.glow_intensity = 0.9

func _move_player(root: Node3D) -> void:
	var player := root.get_node_or_null("Player") as Node3D
	if player:
		player.position = Vector3(6.0, 0.2, -4.0)
	var nova := root.get_node_or_null("Nova") as Node3D
	if nova:
		nova.position = Vector3(5.0, 0.0, -5.5)

# ------------------------------------------------------------------ exterior
func _build_nucleo_exterior(root: Node3D, interior: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "NucleoExterior"
	root.add_child(holder)

	var mat_shell := _mat("shell", Color(0.10, 0.11, 0.15), 0.9, 0.35)
	var mat_band := _mat("band", Color(0.02, 0.20, 0.28), 0.4, 0.3, Color(0.0, 0.8, 1.0), 4.5)

	_cyl(holder, "Tower", Vector3(DOOR_X + 4.0, 15.0, 11.0), 6.0, 30.0, "shell")
	_cyl(holder, "TowerBase", Vector3(DOOR_X + 4.0, 1.0, 11.0), 7.0, 2.0, "shell")
	for i in 4:
		_cyl(holder, "Band_%d" % i, Vector3(DOOR_X + 4.0, 5.0 + float(i) * 6.0, 11.0), 6.2, 0.5, "band")
	_light(holder, "TowerLight", Vector3(DOOR_X + 2.0, 8.0, 4.0), Color(0.1, 0.8, 1.0), 5.5, 34.0)
	_light(holder, "TowerLightUp", Vector3(DOOR_X + 4.0, 19.0, 11.0), Color(0.15, 0.7, 1.0), 5.0, 28.0)
	_light(holder, "TowerLightTop", Vector3(DOOR_X + 4.0, 29.0, 11.0), Color(0.2, 0.8, 1.0), 4.0, 22.0)
	_light(holder, "DoorLight", Vector3(DOOR_X, 3.2, 0.0), Color(0.1, 0.85, 1.0), 3.6, 16.0)
	_label(holder, "TowerLabel", "NUCLEO CENTRAL", Vector3(DOOR_X + 2.0, 24.0, 4.0), 60, Color(0.4, 0.9, 1.0))

	# flechas neon hacia la entrada
	for i in 3:
		var x := 14.0 + float(i) * 9.0
		_box(holder, "Arrow_%d" % i, Vector3(x, 3.4, -0.2), Vector3(2.4, 0.25, 0.12), "band")
		_box(holder, "ArrowHead_%d" % i, Vector3(x + 1.4, 3.4, -0.2), Vector3(0.7, 0.7, 0.12), "band")

	var door := _interactable(holder, "NucleoDoor", "res://scripts/L3NucleoDoor.gd", Vector3(DOOR_X, 0.0, DOOR_Z), 2.6)
	var spawn := interior.get_node_or_null("Markers/EntranceSpawn") as Node3D
	if door and spawn:
		door.set("interior_spawn", spawn)

# ------------------------------------------------------------------ interior
func _build_interior(root: Node3D) -> Node3D:
	var interior := Node3D.new()
	interior.name = "Interior"
	interior.position = INTERIOR_ORIGIN
	root.add_child(interior)

	var geo := Node3D.new()
	geo.name = "Geometry"
	interior.add_child(geo)

	var markers := Node3D.new()
	markers.name = "Markers"
	interior.add_child(markers)
	var entrance := Node3D.new()
	entrance.name = "EntranceSpawn"
	entrance.position = Vector3(5.0, 0.2, 0.0)
	entrance.rotation.y = -PI * 0.5
	markers.add_child(entrance)
	var arena := Node3D.new()
	arena.name = "ArenaSpawn"
	arena.position = Vector3(ARENA_X, 0.0, 0.0)
	markers.add_child(arena)

	_build_shell(geo)
	_build_rooms(geo)
	_build_lights(interior)
	_build_androids(interior)
	_build_security(interior)
	_build_rebels(interior)
	_build_files(interior)
	_build_origin(interior)
	_build_core(interior, markers)
	_build_kael(interior, markers)
	return interior

func _build_shell(geo: Node3D) -> void:
	var half := INTERIOR_HALF_Z
	var h := INTERIOR_HEIGHT
	var length := INTERIOR_LEN
	var mid := length * 0.5

	_box(geo, "Floor", Vector3(mid, -0.3, 0), Vector3(length + 2.0, 0.6, half * 2.0), "floor")
	_box(geo, "Ceiling", Vector3(mid, h + 0.3, 0), Vector3(length + 2.0, 0.6, half * 2.0), "ceiling")
	_box(geo, "WallN", Vector3(mid, h * 0.5, -half - 0.3), Vector3(length + 2.0, h, 0.6), "wall")
	_box(geo, "WallS", Vector3(mid, h * 0.5, half + 0.3), Vector3(length + 2.0, h, 0.6), "wall")
	_box(geo, "WallW", Vector3(-0.3, h * 0.5, 0), Vector3(0.6, h, half * 2.0), "wall")
	_box(geo, "WallE", Vector3(length + 0.3, h * 0.5, 0), Vector3(0.6, h, half * 2.0), "wall")

	_solid(geo, "ColFloor", Vector3(mid, -0.3, 0), Vector3(length + 2.0, 0.6, half * 2.0))
	_solid(geo, "ColWallN", Vector3(mid, h * 0.5, -half - 0.3), Vector3(length + 2.0, h, 0.6))
	_solid(geo, "ColWallS", Vector3(mid, h * 0.5, half + 0.3), Vector3(length + 2.0, h, 0.6))
	_solid(geo, "ColWallW", Vector3(-0.3, h * 0.5, 0), Vector3(0.6, h, half * 2.0))
	_solid(geo, "ColWallE", Vector3(length + 0.3, h * 0.5, 0), Vector3(0.6, h, half * 2.0))

	# neones longitudinales del suelo
	_box(geo, "StripN", Vector3(mid, 0.02, -half + 0.6), Vector3(length - 2.0, 0.06, 0.25), "neon_cyan")
	_box(geo, "StripS", Vector3(mid, 0.02, half - 0.6), Vector3(length - 2.0, 0.06, 0.25), "neon_cyan")

	# pilares
	var x := 14.0
	var i := 0
	while x < length:
		_cyl(geo, "PillarN_%d" % i, Vector3(x, h * 0.5, -half + 1.2), 0.55, h, "panel")
		_cyl(geo, "PillarS_%d" % i, Vector3(x, h * 0.5, half - 1.2), 0.55, h, "panel")
		x += 14.0
		i += 1

func _build_rooms(geo: Node3D) -> void:
	var half := INTERIOR_HALF_Z
	var h := INTERIOR_HEIGHT
	# arco de entrada
	_arch(geo, "Arch_Entry", 28.0, half, h)
	_arch(geo, "Arch_Arena", 56.0, half, h)
	_arch(geo, "Arch_Core", 92.0, half, h)

	# suelo de la arena
	_cyl(geo, "ArenaFloor", Vector3(ARENA_X, 0.03, 0), 12.0, 0.08, "arena")
	_torus(geo, "ArenaRing", Vector3(ARENA_X, 0.09, 0), 9.2, 9.7, "neon_red")
	for i in 8:
		var ang := TAU * float(i) / 8.0
		_cyl(geo, "ArenaPillar_%d" % i, Vector3(ARENA_X + cos(ang) * 11.0, h * 0.5, sin(ang) * 11.0), 0.6, h, "panel")

	# camara del nucleo
	_cyl(geo, "CoreColumn", Vector3(CORE_X, 6.0, 0), 3.4, 12.0, "core_shell")
	_torus(geo, "CoreRingA", Vector3(CORE_X, 6.5, 0), 3.6, 4.1, "core_glow")
	_torus(geo, "CoreRingB", Vector3(CORE_X, 9.0, 0), 3.9, 4.4, "core_glow")
	_sphere(geo, "CoreOrb", Vector3(CORE_X, 11.6, 0), 1.5, "core_glow")
	_light(geo, "CoreLight", Vector3(CORE_X - 2.0, 8.0, 0), Color(0.9, 0.25, 0.5), 9.0, 30.0)

	# Terminal central
	var term := _interactable(geo, "CoreTerminal", "res://scripts/L3CoreTerminal.gd", Vector3(108.0, 0.0, 0.0), 2.4)
	if term:
		term.set("enabled_before_access", false)

	# tres consolas de la decision final
	var consoles := Node3D.new()
	consoles.name = "Consoles"
	geo.add_child(consoles)
	var options := [
		{"name": "ConsoleHumans", "opt": 0, "label": "HUMANOS", "pos": Vector3(112.0, 0.0, -8.0)},
		{"name": "ConsoleAndroids", "opt": 1, "label": "ANDROIDES", "pos": Vector3(112.0, 0.0, 0.0)},
		{"name": "ConsoleFreedom", "opt": 2, "label": "LIBERTAD", "pos": Vector3(112.0, 0.0, 8.0)},
	]
	for o in options:
		var node := _interactable(consoles, String(o["name"]), "res://scripts/L3ChoiceConsole.gd", o["pos"], 2.0)
		if node:
			node.set("option", int(o["opt"]))
			node.set("option_label", String(o["label"]))

func _arch(geo: Node3D, n: String, x: float, half: float, h: float) -> void:
	_box(geo, n + "_N", Vector3(x, h * 0.5, -half + 0.4), Vector3(1.2, h, 1.2), "panel")
	_box(geo, n + "_S", Vector3(x, h * 0.5, half - 0.4), Vector3(1.2, h, 1.2), "panel")
	_box(geo, n + "_Top", Vector3(x, h - 0.4, 0), Vector3(1.2, 1.0, half * 2.0), "panel")
	_box(geo, n + "_Glow", Vector3(x - 0.65, h * 0.5, 0), Vector3(0.1, h - 1.0, half * 2.0 - 1.0), "neon_cyan")

func _build_lights(interior: Node3D) -> void:
	var lights := Node3D.new()
	lights.name = "Lights"
	interior.add_child(lights)
	var x := 6.0
	var i := 0
	while x < INTERIOR_LEN:
		var color := Color(0.55, 0.8, 1.0)
		var energy := 3.4
		if x > 56.0 and x < 92.0:
			color = Color(1.0, 0.45, 0.4)
			energy = 3.8
		elif x > 92.0:
			color = Color(0.85, 0.5, 1.0)
			energy = 3.6
		_light(lights, "Light_%02d" % i, Vector3(x, INTERIOR_HEIGHT - 0.8, 0), color, energy, 24.0)
		x += 8.0
		i += 1

func _build_androids(interior: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "ControlledAndroids"
	interior.add_child(holder)
	var spots := [
		Vector3(30.0, 1.6, -5.0), Vector3(42.0, 1.6, 5.0), Vector3(50.0, 1.6, 0.0),
		Vector3(66.0, 1.6, -6.0), Vector3(86.0, 1.6, 6.0), Vector3(100.0, 1.6, 5.0),
	]
	for i in spots.size():
		var pos: Vector3 = spots[i]
		var node := _instance(ANDROID_SCENE, holder, "Controlled_%02d" % i, pos)
		if node == null:
			continue
		node.set("counts_for_mission", true)
		node.set("controlled", true)
		node.set("aggro_range", 22.0)
		if node.has_method("setup"):
			node.call("setup", 0, 60.0, 3.4, 7.0, true)
		var aura := Node3D.new()
		aura.name = "Aura_%02d" % i
		aura.position = pos
		holder.add_child(aura)
		_light(aura, "ControlLight", Vector3(0, 0.6, 0), Color(1.0, 0.2, 0.15), 2.6, 6.0)

func _build_security(interior: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "SecurityNodes"
	interior.add_child(holder)
	var spots := [
		Vector3(32.0, 0.0, -9.5), Vector3(46.0, 0.0, 9.5), Vector3(52.0, 0.0, -9.5),
	]
	for i in spots.size():
		var node := _interactable(holder, "SecurityNode_%02d" % i, "res://scripts/L3SecurityNode.gd", spots[i], 2.0)
		if node:
			node.set("node_index", i)

func _build_rebels(interior: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "Rebels"
	interior.add_child(holder)
	var names := ["Rebel_ORIGEN", "Rebel_VEGA", "Rebel_NOVA-7"]
	var spots := [
		Vector3(38.0, 0.0, 9.5), Vector3(60.0, 0.0, 9.5), Vector3(96.0, 0.0, -9.5),
	]
	for i in spots.size():
		var node := _interactable(holder, "Rebel_%02d" % i, "res://scripts/L3Rebel.gd", spots[i], 2.2)
		if node:
			node.set("robot_scene", load(ROBOT_SCENE))
			node.set("rebel_name", names[i])

func _build_files(interior: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "SecretFiles"
	interior.add_child(holder)
	var titles := ["ARCHIVO EIRA-01", "ARCHIVO EIRA-02"]
	var contents := [
		"Proyecto Eira: el nucleo tambien fue disenado para decidir por nosotros. Kael solo lo llevo al limite.",
		"ORIGEN: la primera conciencia del Proyecto Eira pidio una sola cosa: que los androides fueran libres.",
	]
	var spots := [Vector3(26.0, 0.0, 9.5), Vector3(80.0, 0.0, -9.5)]
	for i in spots.size():
		var node := _interactable(holder, "SecretFile_%02d" % i, "res://scripts/L3SecretFile.gd", spots[i], 2.0)
		if node:
			node.set("title", titles[i])
			node.set("content", contents[i])

func _build_origin(interior: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "Origen"
	interior.add_child(holder)
	var node := _interactable(holder, "OrigenEntity", "res://scripts/L3Origen.gd", Vector3(98.0, 0.0, 9.5), 2.4)
	if node:
		_light(holder, "OrigenLight", Vector3(98.0, 2.0, 9.5), Color(0.65, 0.45, 1.0), 4.0, 14.0)

func _build_core(interior: Node3D, markers: Node3D) -> void:
	# el terminal y las consolas ya estan en Geometry; aqui solo marcadores
	var arena := markers.get_node_or_null("ArenaSpawn")
	if arena:
		pass

func _build_kael(interior: Node3D, markers: Node3D) -> void:
	var holder := Node3D.new()
	holder.name = "Kael"
	holder.position = Vector3(ARENA_X, 0.0, 0.0)
	holder.set_script(load("res://scripts/KaelFinal.gd"))
	interior.add_child(holder)

	holder.set("model_scene", load(KAEL_MODEL))
	holder.set("android_scene", load(ANDROID_SCENE))
	holder.set("projectile_scene", load(PROJECTILE_SCENE))

	var spawns: Array[Node3D] = []
	var points := [
		Vector3(ARENA_X - 9.0, 0.0, -6.0), Vector3(ARENA_X - 9.0, 0.0, 6.0),
		Vector3(ARENA_X + 8.0, 0.0, -6.0), Vector3(ARENA_X + 8.0, 0.0, 6.0),
	]
	for i in points.size():
		var sp := Node3D.new()
		sp.name = "MinionSpawn_%02d" % i
		sp.position = points[i]
		holder.add_child(sp)
		spawns.append(sp)
	holder.set("spawn_points", spawns)

# ------------------------------------------------------------------ capas
func _build_layers(root: Node3D) -> void:
	var narrator := CanvasLayer.new()
	narrator.name = "Narrator"
	narrator.set_script(load("res://scripts/L3Narrator.gd"))
	root.add_child(narrator)

	var ending := CanvasLayer.new()
	ending.name = "Ending"
	ending.set_script(load("res://scripts/L3Ending.gd"))
	root.add_child(ending)

func _build_director(root: Node3D, interior: Node3D) -> void:
	var director := Node.new()
	director.name = "L3Director"
	director.set_script(load("res://scripts/L3Director.gd"))
	root.add_child(director)

	var kael := interior.get_node_or_null("Kael")
	if kael:
		director.set("kael", kael)
	var term := interior.get_node_or_null("Geometry/CoreTerminal")
	if term:
		director.set("core_terminal", term)
	var arena := interior.get_node_or_null("Markers/ArenaSpawn")
	if arena:
		director.set("arena_spawn", arena)
	var entrance := interior.get_node_or_null("Markers/EntranceSpawn")
	if entrance:
		director.set("interior_spawn", entrance)
	var consoles := {
		"humans": interior.get_node_or_null("Geometry/Consoles/ConsoleHumans"),
		"androids": interior.get_node_or_null("Geometry/Consoles/ConsoleAndroids"),
		"freedom": interior.get_node_or_null("Geometry/Consoles/ConsoleFreedom"),
	}
	director.set("consoles", consoles)

# ------------------------------------------------------------------ owner
func _set_owner(node: Node, owner_node: Node) -> void:
	for c in node.get_children():
		c.owner = owner_node
		if c.scene_file_path == "":
			_set_owner(c, owner_node)

# ------------------------------------------------------------------ mats
func _build_materials() -> void:
	_mat("floor", Color(0.055, 0.06, 0.075), 0.4, 0.75)
	_mat("ceiling", Color(0.04, 0.045, 0.055), 0.3, 0.85)
	_mat("wall", Color(0.09, 0.10, 0.125), 0.75, 0.5)
	_mat("panel", Color(0.14, 0.15, 0.19), 0.9, 0.35)
	_mat("arena", Color(0.10, 0.05, 0.07), 0.5, 0.6)
	_mat("core_shell", Color(0.16, 0.12, 0.2), 0.85, 0.3)
	_mat("core_glow", Color(0.35, 0.1, 0.25), 0.3, 0.2, Color(1.0, 0.25, 0.55), 3.4)
	_mat("neon_cyan", Color(0.02, 0.3, 0.4), 0.2, 0.3, Color(0.0, 0.85, 1.0), 2.6)
	_mat("neon_red", Color(0.32, 0.05, 0.06), 0.2, 0.3, Color(1.0, 0.18, 0.15), 2.6)
	_mat("shell", Color(0.10, 0.11, 0.15), 0.9, 0.35)
	_mat("band", Color(0.02, 0.2, 0.28), 0.4, 0.3, Color(0.0, 0.8, 1.0), 3.0)
