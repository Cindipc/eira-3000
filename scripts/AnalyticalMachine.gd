extends Node3D

const BODY_LAYER := 8
const WEAKPOINT_LAYER := 4

@export var max_health := 450.0
@export var weak_point_health := 140.0
@export var move_speed := 1.25
@export var projectile_scene: PackedScene = null
@export var android_scene: PackedScene = null
@export var body_radius := 1.5

var health := 450.0
var weak_points: Array[Dictionary] = []
var player: Node3D = null
var _attack_timer := 3.0
var _spawn_timer := 12.0
var _ring_a: Node3D = null
var _ring_b: Node3D = null
var _eye: MeshInstance3D = null
var _eye_light: OmniLight3D = null
var _core: MeshInstance3D = null
var _core_light: OmniLight3D = null
var _phase := 1
var _dead := false
var _body: StaticBody3D = null
var _hit_flash := 0.0
var _face_yaw := 0.0

func _ready() -> void:
	add_to_group("boss")
	_build_body()
	_build_visual()
	health = max_health
	GameState.spawn_boss(self, max_health)
	GameState.notify("MÁQUINA ANALÍTICA ACTIVADA", Color(1.0, 0.3, 0.35))

func _build_body() -> void:
	_body = StaticBody3D.new()
	_body.name = "Body"
	_body.collision_layer = BODY_LAYER
	_body.collision_mask = 0
	add_child(_body)

	var cs := CollisionShape3D.new()
	cs.name = "BodyShape"
	var box := BoxShape3D.new()
	box.size = Vector3(2.4, 3.4, 2.4)
	cs.shape = box
	cs.position = Vector3(0, 2.1, 0)
	_body.add_child(cs)

	var base := CollisionShape3D.new()
	base.name = "BaseShape"
	var cyl := CylinderShape3D.new()
	cyl.radius = 2.4
	cyl.height = 0.8
	base.shape = cyl
	base.position = Vector3(0, 0.4, 0)
	_body.add_child(base)

	for wp in _weak_point_offsets():
		var s := CollisionShape3D.new()
		s.name = "WeakShape_%d" % weak_points.size()
		var sph := SphereShape3D.new()
		sph.radius = 0.55
		s.shape = sph
		s.position = wp
		_body.add_child(s)

func _weak_point_offsets() -> Array[Vector3]:
	return [
		Vector3(0.0, 2.6, 1.45),
		Vector3(-1.45, 1.5, 0.5),
		Vector3(1.45, 1.5, 0.5),
	]

func _build_visual() -> void:
	var root := Node3D.new()
	root.name = "Machine"
	add_child(root)

	var mat_base := _mat(Color(0.07, 0.08, 0.10), 0.9, 0.35)
	var mat_dark := _mat(Color(0.04, 0.045, 0.055), 0.8, 0.5)
	var mat_steel := _mat(Color(0.22, 0.24, 0.28), 0.95, 0.25)
	var mat_tech := _mat(Color(0.05, 0.16, 0.26), 0.6, 0.35, Color(0.0, 0.8, 1.0), 2.2)
	var mat_hot := _mat(Color(0.25, 0.06, 0.02), 0.4, 0.4, Color(1.0, 0.25, 0.1), 4.0)

	var base := _cyl(root, "Base", 2.4, 0.8, mat_base, Vector3(0, 0.4, 0))
	var column := _mesh(root, "Column", BoxMesh.new(), 1.7, 2.4, 1.7, mat_dark, Vector3(0, 2.0, 0))
	var head := _mesh(root, "Head", BoxMesh.new(), 2.0, 1.1, 1.7, mat_steel, Vector3(0, 3.6, 0.1))
	var visor := _mesh(root, "Visor", BoxMesh.new(), 1.6, 0.34, 0.12, mat_tech, Vector3(0, 3.7, 0.95))

	_eye = _sphere(root, "Eye", 0.42, mat_hot, Vector3(0, 4.3, 0.2))
	_eye_light = OmniLight3D.new()
	_eye_light.light_color = Color(1.0, 0.25, 0.1)
	_eye_light.light_energy = 5.0
	_eye_light.omni_range = 10.0
	_eye_light.position = Vector3(0, 4.3, 0.2)
	root.add_child(_eye_light)

	_ring_a = Node3D.new()
	_ring_a.name = "RingA"
	_ring_a.position = Vector3(0, 2.6, 0)
	root.add_child(_ring_a)
	var torus_a := TorusMesh.new()
	torus_a.inner_radius = 1.9
	torus_a.outer_radius = 2.25
	torus_a.rings = 24
	torus_a.ring_segments = 10
	_mesh(_ring_a, "RingMesh", torus_a, 1, 1, 1, mat_tech, Vector3.ZERO, Vector3(PI * 0.5, 0, 0))

	_ring_b = Node3D.new()
	_ring_b.name = "RingB"
	_ring_b.position = Vector3(0, 2.2, 0)
	root.add_child(_ring_b)
	var torus_b := TorusMesh.new()
	torus_b.inner_radius = 1.55
	torus_b.outer_radius = 1.85
	torus_b.rings = 24
	torus_b.ring_segments = 10
	_mesh(_ring_b, "RingMesh", torus_b, 1, 1, 1, mat_hot, Vector3.ZERO, Vector3(0, 0, 0))

	_core = _sphere(root, "Core", 0.62, mat_tech, Vector3(0, 2.6, 0.0))
	_core_light = OmniLight3D.new()
	_core_light.light_color = Color(0.2, 0.9, 1.0)
	_core_light.light_energy = 3.0
	_core_light.omni_range = 9.0
	_core_light.position = Vector3(0, 2.6, 0)
	root.add_child(_core_light)

	for i in 3:
		_build_arm(root, i, mat_dark, mat_steel, mat_hot)

	for i in _weak_point_offsets().size():
		var off: Vector3 = _weak_point_offsets()[i]
		var wp := Node3D.new()
		wp.name = "WeakPoint_%d" % (i + 1)
		wp.position = off
		root.add_child(wp)
		var orb := _sphere(wp, "Orb", 0.5, mat_hot, Vector3.ZERO)
		var wl := OmniLight3D.new()
		wl.light_color = Color(1.0, 0.35, 0.12)
		wl.light_energy = 4.0
		wl.omni_range = 7.0
		wp.add_child(wl)
		weak_points.append({
			"node": wp,
			"mesh": orb,
			"light": wl,
			"hp": weak_point_health,
			"alive": true,
			"offset": off,
		})

func _build_arm(parent: Node3D, index: int, mat_dark: StandardMaterial3D, mat_steel: StandardMaterial3D, mat_hot: StandardMaterial3D) -> void:
	var pivot := Node3D.new()
	pivot.name = "Arm_%d" % index
	pivot.position = Vector3(0, 2.9, 0)
	parent.add_child(pivot)
	var a := float(index - 1) * 1.15
	pivot.rotation.y = a
	_mesh(pivot, "Shoulder", BoxMesh.new(), 0.9, 0.9, 0.9, mat_steel, Vector3(1.35, 0, 0))
	_mesh(pivot, "Upper", BoxMesh.new(), 0.45, 2.2, 0.45, mat_dark, Vector3(1.9, -0.6, 0))
	_mesh(pivot, "Fore", BoxMesh.new(), 0.38, 1.7, 0.38, mat_dark, Vector3(2.45, -1.6, 0), Vector3(0.5, 0, 0))
	_mesh(pivot, "Tip", SphereMesh.new(), 0.32, 0.32, 0.32, mat_hot, Vector3(2.85, -2.3, 0))

func _mat(albedo: Color, metallic: float, roughness: float, emission: Color = Color(0, 0, 0), energy: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.metallic = metallic
	m.roughness = roughness
	if energy > 0.0:
		m.emission_enabled = true
		m.emission = emission
		m.emission_energy_multiplier = energy
	return m

func _mesh(parent: Node3D, n: String, mesh: Mesh, sx: float, sy: float, sz: float, mat: StandardMaterial3D, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = n
	mi.mesh = mesh
	mi.scale = Vector3(sx, sy, sz)
	mi.position = pos
	mi.rotation = rot
	mi.material_override = mat
	parent.add_child(mi)
	return mi

func _sphere(parent: Node3D, n: String, radius: float, mat: StandardMaterial3D, pos: Vector3) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 16
	sm.rings = 8
	return _mesh(parent, n, sm, 1, 1, 1, mat, pos)

func _cyl(parent: Node3D, n: String, radius: float, height: float, mat: StandardMaterial3D, pos: Vector3) -> MeshInstance3D:
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 20
	return _mesh(parent, n, cm, 1, 1, 1, mat, pos)

func _process(delta: float) -> void:
	if _dead:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node3D
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta * 3.0)

	if _ring_a:
		_ring_a.rotation.y += delta * (0.8 + 0.4 * _phase)
		_ring_a.rotation.z = sin(Time.get_ticks_msec() * 0.0004) * 0.3
	if _ring_b:
		_ring_b.rotation.x += delta * (1.4 + 0.6 * _phase)
	if _eye:
		var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.006) * 0.08
		_eye.scale = Vector3.ONE * pulse
	if _core:
		var s := 1.0 + sin(Time.get_ticks_msec() * 0.004) * 0.09
		_core.scale = Vector3.ONE * s

	for wp in weak_points:
		if not wp["alive"]:
			continue
		var node: Node3D = wp["node"]
		node.position.y = (wp["offset"] as Vector3).y + sin(Time.get_ticks_msec() * 0.003 + wp["offset"].x) * 0.12
		var light: OmniLight3D = wp["light"]
		light.light_energy = 3.0 + sin(Time.get_ticks_msec() * 0.008) * 1.5

func _physics_process(delta: float) -> void:
	if _dead or player == null:
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist > 6.0:
		var dir := to_player.normalized()
		global_position += dir * move_speed * delta
	if dist > 0.1:
		_face_yaw = atan2(to_player.x, to_player.z)
		rotation.y = lerp_angle(rotation.y, _face_yaw, clampf(delta * 2.0, 0.0, 1.0))

	_attack_timer -= delta
	if _attack_timer <= 0.0:
		_attack()
		_attack_timer = [2.6, 2.0, 1.5][_phase - 1]

	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_timer = [16.0, 12.0, 9.0][_phase - 1]
		_spawn_androids()

func _attack() -> void:
	if projectile_scene == null:
		return
	var to_player := player.global_position - (global_position + Vector3.UP * 4.3)
	to_player.y = 0.0
	var dir := to_player.normalized()
	var shots := 1
	if _phase == 2:
		shots = 3
	elif _phase >= 3:
		shots = 4
	for i in shots:
		var d := dir.rotated(Vector3.UP, (i - (shots - 1) * 0.5) * 0.12)
		var proj := projectile_scene.instantiate() as Node3D
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position + Vector3.UP * 4.3 + d * 1.0
		if proj.has_method("setup"):
			proj.setup(d, 14.0, 17.0)
	if _eye:
		_eye_light.light_energy = 12.0

func _spawn_androids() -> void:
	if android_scene == null:
		return
	var count := 1 if _phase < 3 else 2
	for i in count:
		var a := randf() * TAU
		var pos := global_position + Vector3(cos(a) * 7.0, 0.2, sin(a) * 7.0)
		var android := android_scene.instantiate() as Node3D
		get_tree().current_scene.add_child(android)
		android.global_position = pos
		if android.has_method("setup"):
			android.setup(0, 70.0, 3.6, 11.0, true)
		GameState.notify("La Máquina Analítica despliega androides", Color(1.0, 0.5, 0.4))

func take_damage(amount: float, hit_pos: Vector3 = Vector3.ZERO, _dir: Vector3 = Vector3.ZERO) -> bool:
	if _dead:
		return false
	var dmg := amount
	var wp_hit: Variant = _weak_point_at(hit_pos)
	if wp_hit != null:
		wp_hit["hp"] = float(wp_hit["hp"]) - amount
		var orb: MeshInstance3D = wp_hit["mesh"]
		orb.scale = Vector3.ONE * 0.28
		var wlight: OmniLight3D = wp_hit["light"]
		wlight.light_energy = 0.4
		wp_hit["alive"] = false
		GameState.notify("Núcleo de la Máquina Analítica destruido", Color(1.0, 0.8, 0.3))
		if _all_weak_points_destroyed():
			GameState.notify("¡NÚCLEO EXPUESTO! Dispara al centro", Color(0.4, 1.0, 0.6))
	else:
		dmg = amount * 0.45
		if _all_weak_points_destroyed():
			dmg = amount * 0.75
	health -= dmg
	_hit_flash = 1.0
	if _eye_light:
		_eye_light.light_energy = 8.0
	GameState.set_boss_health(maxf(0.0, health), max_health)
	_update_phase()
	if health <= 0.0:
		_die()
		return true
	return false

func is_headshot(hit_pos: Vector3) -> bool:
	var local := global_transform.affine_inverse() * hit_pos
	return local.y > 4.0

func _weak_point_at(hit_pos: Vector3) -> Variant:
	for wp in weak_points:
		if not wp["alive"]:
			continue
		var node: Node3D = wp["node"]
		if node.global_position.distance_to(hit_pos) < 0.85:
			return wp
	return null

func _all_weak_points_destroyed() -> bool:
	for wp in weak_points:
		if wp["alive"]:
			return false
	return true

func _update_phase() -> void:
	var ratio := health / max_health
	var new_phase := 1
	if ratio <= 0.34:
		new_phase = 3
	elif ratio <= 0.67:
		new_phase = 2
	if new_phase != _phase:
		_phase = new_phase
		GameState.notify("La Máquina Analítica entra en fase %d" % _phase, Color(1.0, 0.45, 0.35))

func _die() -> void:
	_dead = true
	GameState.boss_down()
	GameState.notify("MÁQUINA ANALÍTICA DESTRUIDA", Color(0.4, 1.0, 0.7))
	if _body:
		_body.collision_layer = 0
	_reward_ammo()
	for wp in weak_points:
		var wlight: OmniLight3D = wp["light"]
		wlight.light_energy = 0.0
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.6, 0.2)
	light.light_energy = 20.0
	light.omni_range = 22.0
	light.position = global_position + Vector3.UP * 2.5
	get_tree().current_scene.add_child(light)
	var lt := create_tween()
	lt.tween_property(light, "light_energy", 0.0, 1.4)
	lt.tween_callback(light.queue_free)
	for i in 16:
		var piece := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(randf_range(0.15, 0.5), randf_range(0.15, 0.5), randf_range(0.15, 0.5))
		piece.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.22, 0.26)
		mat.metallic = 0.9
		mat.roughness = 0.35
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.4, 0.1)
		mat.emission_energy_multiplier = 2.0
		piece.material_override = mat
		piece.position = global_position + Vector3(randf_range(-1.2, 1.2), randf_range(0.5, 4.2), randf_range(-1.2, 1.2))
		get_tree().current_scene.add_child(piece)
		var vel := Vector3(randf_range(-6.0, 6.0), randf_range(3.0, 9.0), randf_range(-6.0, 6.0))
		var pt := create_tween()
		pt.tween_property(piece, "position", piece.position + vel * 0.8, 0.9).set_trans(Tween.TRANS_QUAD)
		pt.tween_property(piece, "position:y", piece.position.y - 2.0, 1.2)
		pt.parallel().tween_property(piece, "scale", Vector3.ZERO, 1.2)
		pt.tween_callback(piece.queue_free)
	var tw := create_tween()
	tw.tween_interval(0.6)
	var visual := get_node_or_null("Machine") as Node3D
	if visual:
		tw.tween_property(visual, "scale", Vector3(0.01, 0.35, 0.01), 0.5)
	else:
		tw.tween_property(self, "scale", Vector3(0.01, 0.4, 0.01), 0.5)
	tw.parallel().tween_property(self, "position:y", position.y - 1.5, 0.5)
	tw.tween_callback(queue_free)

func _reward_ammo() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		return
	var weapon := player.get_node_or_null("CameraPivot/Camera3D/Weapon")
	if weapon and weapon.has_method("add_ammo"):
		weapon.add_ammo(40)
