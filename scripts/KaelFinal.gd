extends Node3D

## Kael, jefe final del Nivel 3.
##
## Cuatro fases:
##   1) golpes fisicos y disparos,
##   2) controla androides (invoca refuerzos),
##   3) usa el poder del Nucleo (ondas de choque),
##   4) se arrodilla: Eira llega al sistema central y decide.
## No muere por dano: el desenlace lo decide Eira.

const BODY_LAYER := 8

@export var max_health := 900.0
@export var phase2_at := 0.66
@export var phase3_at := 0.33
@export var move_speed := 2.4
@export var melee_range := 3.4
@export var melee_damage := 16.0
@export var melee_period := 1.7
@export var ranged_damage := 12.0
@export var ranged_period := 3.4
@export var shockwave_radius := 8.5
@export var shockwave_damage := 18.0
@export var minion_count := 2
@export var minion_period := 9.0
@export var model_scene: PackedScene = null
@export var android_scene: PackedScene = null
@export var projectile_scene: PackedScene = null
@export var spawn_points: Array[Node3D] = []

var health := 900.0
var phase := 1
var armed := false
var arena_open := false
var downed := false
var director: Node = null
var player: Node3D = null

var _model: Node3D = null
var _rig: Node3D = null
var _aura: OmniLight3D = null
var _body: StaticBody3D = null
var _melee_timer := 1.5
var _ranged_timer := 2.0
var _minion_timer := 6.0
var _shock_timer := 5.0
var _face_yaw := 0.0
var _flash := 0.0

func _ready() -> void:
	add_to_group("boss")
	add_to_group("kael")
	health = max_health
	_build_body()
	_build_model()
	GameState.set_boss_health(health, max_health)

func _build_body() -> void:
	_body = StaticBody3D.new()
	_body.name = "Body"
	_body.collision_layer = BODY_LAYER
	_body.collision_mask = 0
	add_child(_body)
	var cs := CollisionShape3D.new()
	cs.name = "BodyShape"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.9
	cs.shape = capsule
	cs.position = Vector3(0, 0.95, 0)
	_body.add_child(cs)

func _build_model() -> void:
	_model = Node3D.new()
	_model.name = "Visual"
	add_child(_model)

	_aura = OmniLight3D.new()
	_aura.name = "Aura"
	_aura.light_color = Color(1.0, 0.25, 0.15)
	_aura.light_energy = 2.2
	_aura.omni_range = 9.0
	_aura.position = Vector3(0, 1.2, 0)
	_model.add_child(_aura)

	if model_scene != null:
		var inst := model_scene.instantiate() as Node3D
		if inst != null:
			inst.name = "KaelModel"
			_model.add_child(inst)
			_rig = Node3D.new()
			_rig.name = "Rig"
			_rig.set_script(load("res://scripts/KaelRig.gd"))
			inst.add_child(_rig)
	else:
		_build_fallback_model()

func _build_fallback_model() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.08, 0.1)
	mat.metallic = 0.85
	mat.roughness = 0.35
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.2, 0.1)
	mat.emission_energy_multiplier = 1.6
	var torso := MeshInstance3D.new()
	torso.name = "Torso"
	var bm := BoxMesh.new()
	bm.size = Vector3(0.6, 1.0, 0.35)
	torso.mesh = bm
	torso.material_override = mat
	torso.position = Vector3(0, 1.25, 0)
	_model.add_child(torso)
	var head := MeshInstance3D.new()
	head.name = "Head"
	var sm := SphereMesh.new()
	sm.radius = 0.2
	sm.height = 0.4
	head.mesh = sm
	head.material_override = mat
	head.position = Vector3(0, 1.95, 0)
	_model.add_child(head)

func arm(dir: Node) -> void:
	director = dir
	armed = true

func open_arena() -> void:
	if arena_open:
		return
	arena_open = true
	GameState.set_boss_health(health, max_health)
	GameState.notify("KAEL TE ESPERA EN LA CAMARA DEL NÚCLEO", Color(1.0, 0.35, 0.3))
	_set_rig_state(0)

func _set_rig_state(value: int) -> void:
	if _rig and _rig.has_method("set_state"):
		_rig.call("set_state", value)

func _physics_process(delta: float) -> void:
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.0)
	if _aura:
		_aura.light_energy = 1.6 + sin(Time.get_ticks_msec() * 0.004) * 0.8
	if not armed or not arena_open or downed:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node3D
		return

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var dir := to_player.normalized() if dist > 0.001 else Vector3.FORWARD
	if dist > 0.05:
		_face_yaw = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, _face_yaw, clampf(delta * 4.0, 0.0, 1.0))

	var speed := move_speed * (1.45 if phase >= 3 else 1.0)
	if dist > melee_range * 0.8:
		global_position += dir * speed * delta
		_set_rig_state(1)
	else:
		_set_rig_state(0)

	_melee_timer -= delta
	_ranged_timer -= delta
	_minion_timer -= delta
	_shock_timer -= delta

	if dist < melee_range and _melee_timer <= 0.0:
		_melee_timer = melee_period * (0.75 if phase >= 3 else 1.0)
		_melee(dir)
	if _ranged_timer <= 0.0:
		_ranged_timer = ranged_period * (0.7 if phase >= 3 else 1.0)
		_ranged(dir)
	if phase == 2 and _minion_timer <= 0.0:
		_minion_timer = minion_period
		_spawn_minions()
	if phase >= 3 and _shock_timer <= 0.0:
		_shock_timer = 4.2
		_shockwave()

func _melee(dir: Vector3) -> void:
	_set_rig_state(2)
	await get_tree().create_timer(0.2).timeout
	if player == null or not is_instance_valid(player):
		return
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > melee_range * 1.6:
		return
	if player.has_method("take_damage"):
		player.take_damage(melee_damage, global_position)
	GameState.notify("Kael golpea", Color(1.0, 0.4, 0.35))

func _ranged(dir: Vector3) -> void:
	if projectile_scene == null:
		return
	var shots := 1
	if phase == 2:
		shots = 2
	elif phase >= 3:
		shots = 3
	for i in shots:
		var d := dir.rotated(Vector3.UP, (i - (shots - 1) * 0.5) * 0.13)
		var proj := projectile_scene.instantiate() as Node3D
		get_tree().current_scene.add_child(proj)
		proj.global_position = global_position + Vector3.UP * 1.5 + d * 0.8
		if proj.has_method("setup"):
			proj.setup(d, ranged_damage, 16.0)

func _spawn_minions() -> void:
	if android_scene == null:
		return
	var count := minion_count
	for i in count:
		var pos := global_position + Vector3(randf_range(-8.0, 8.0), 0.2, randf_range(-8.0, 8.0))
		if spawn_points.size() > 0:
			pos = spawn_points[i % spawn_points.size()].global_position
		var android := android_scene.instantiate() as Node3D
		get_tree().current_scene.add_child(android)
		android.global_position = pos
		if android.has_method("setup"):
			android.setup(0, 70.0, 3.6, 11.0, true)
		android.set("counts_for_mission", false)
	GameState.notify("Kael recluta androides controlados", Color(1.0, 0.45, 0.35))

func _shockwave() -> void:
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.6
	torus.outer_radius = 1.1
	ring.mesh = torus
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.2, 0.5)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.6)
	mat.emission_energy_multiplier = 4.0
	ring.material_override = mat
	ring.rotation_degrees = Vector3(90, 0, 0)
	ring.position = Vector3(0, 0.4, 0)
	add_child(ring)
	var tw := create_tween()
	tw.tween_property(ring, "scale", Vector3.ONE * shockwave_radius, 0.7)
	tw.parallel().tween_property(mat, "albedo_color:a", 0.0, 0.7)
	tw.tween_callback(ring.queue_free)
	GameState.notify("ONDA DE CHOQUE DEL NÚCLEO", Color(1.0, 0.3, 0.55))
	if player == null or not is_instance_valid(player):
		return
	var d := Vector2(
		player.global_position.x - global_position.x,
		player.global_position.z - global_position.z).length()
	if d <= shockwave_radius and player.has_method("take_damage"):
		player.take_damage(shockwave_damage, global_position)

func take_damage(amount: float, hit_pos: Vector3 = Vector3.ZERO, _dir: Vector3 = Vector3.ZERO) -> bool:
	if downed or not arena_open:
		return false
	health -= maxf(0.0, amount)
	_flash = 1.0
	GameState.set_boss_health(maxf(0.0, health), max_health)
	_update_phase()
	if _rig and _rig.has_method("set_state"):
		_rig.call("set_state", 3)
		var timer := get_tree().create_timer(0.18)
		timer.timeout.connect(func() -> void:
			if not downed and health > 0.0:
				_set_rig_state(0))
	if health <= 0.0:
		_down()
		return true
	return false

func is_headshot(hit_pos: Vector3) -> bool:
	var local := global_transform.affine_inverse() * hit_pos
	return local.y > 1.65

func _update_phase() -> void:
	var ratio := health / maxf(1.0, max_health)
	var new_phase := 1
	if ratio <= phase3_at:
		new_phase = 3
	elif ratio <= phase2_at:
		new_phase = 2
	if new_phase != phase:
		phase = new_phase
		GameState.notify("KAEL - FASE %d" % phase, Color(1.0, 0.45, 0.3))
		if director and director.has_method("on_kael_phase"):
			director.call("on_kael_phase", phase)
		if _aura:
			if phase == 2:
				_aura.light_color = Color(1.0, 0.45, 0.2)
			elif phase >= 3:
				_aura.light_color = Color(1.0, 0.15, 0.45)

func _down() -> void:
	downed = true
	health = 0.0
	GameState.set_boss_health(0.0, max_health)
	_set_rig_state(4)
	GameState.notify("KAEL SE ARRODILLA", Color(0.6, 0.9, 1.0))
	if director and director.has_method("on_kael_downed"):
		director.call("on_kael_downed")

func reset_boss() -> void:
	## Reinicia a Kael cuando la linea temporal se reinicia.
	downed = false
	phase = 1
	health = max_health
	_set_rig_state(0)
	GameState.set_boss_health(health, max_health)
	GameState.notify("Kael vuelve a levantarse", Color(1.0, 0.5, 0.35))
