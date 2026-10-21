extends Node3D

signal fired
signal hit_confirmed(killed: bool)
signal ammo_changed(magazine: int, reserve: int)

const WORLD_LAYER := 1
const ENEMY_LAYER := 4
const BOSS_LAYER := 8

@export var damage := 34.0
@export var fire_rate := 0.16
@export var mag_size := 12
@export var reserve_max := 120
@export var reload_time := 1.15
@export var max_range := 140.0
@export var spread := 0.006
@export var headshot_multiplier := 2.0

var magazine: int = 12
var reserve: int = 60
var current_target: Node3D = null
var _cooldown: float = 0.0
var _reload_left: float = 0.0
var _reloading := false
var _kick := 0.0
var _shake := 0.0
var _tracer_index := 0
var _tracers: Array[MeshInstance3D] = []
var _impacts: Array[MeshInstance3D] = []
var _flash_timer := 0.0

@onready var gun_root: Node3D = $GunRoot
@onready var muzzle: Node3D = $GunRoot/Muzzle
@onready var flash_light: OmniLight3D = $GunRoot/Muzzle/FlashLight
@onready var flash_mesh: MeshInstance3D = $GunRoot/Muzzle/FlashMesh
@onready var tracer_root: Node3D = $Tracers
@onready var impact_root: Node3D = $Impacts

func _ready() -> void:
	magazine = mag_size
	_collect_children()
	GameState.set_ammo(magazine, reserve)
	flash_light.visible = false
	flash_mesh.visible = false

func _collect_children() -> void:
	for c in tracer_root.get_children():
		if c is MeshInstance3D:
			_tracers.append(c)
			(c as MeshInstance3D).visible = false
	for c in impact_root.get_children():
		if c is MeshInstance3D:
			_impacts.append(c)
			(c as MeshInstance3D).visible = false

func _process(delta: float) -> void:
	if not is_instance_valid(current_target):
		current_target = null
	if _cooldown > 0.0:
		_cooldown -= delta
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			flash_light.visible = false
			flash_mesh.visible = false
	if _reloading:
		_reload_left -= delta
		if _reload_left <= 0.0:
			_finish_reload()
	if _kick > 0.0:
		_kick = maxf(0.0, _kick - delta * 4.0)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 5.0)
	_update_view()

func _update_view() -> void:
	if gun_root == null:
		return
	gun_root.visible = false
	var cam := get_viewport().get_camera_3d()
	if cam:
		cam.h_offset = _shake * randf_range(-0.02, 0.02)
		cam.v_offset = _kick * 0.02

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			try_fire()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func try_fire() -> void:
	if _reloading or _cooldown > 0.0:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("take_damage") and player.dead:
		return
	if magazine <= 0:
		if reserve > 0:
			start_reload()
		else:
			GameState.notify("Sin munición", Color(1.0, 0.6, 0.2))
			return
	magazine -= 1
	_cooldown = fire_rate
	GameState.set_ammo(magazine, reserve)
	emit_signal("fired")
	_shoot()

func _shoot() -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var player := get_tree().get_first_node_in_group("player")
	var origin := cam.global_position
	var dir := -cam.global_transform.basis.z
	dir = dir.normalized()
	dir = (dir + cam.global_transform.basis.x * randf_range(-spread, spread)
			+ cam.global_transform.basis.y * randf_range(-spread, spread)).normalized()

	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(origin, origin + dir * max_range)
	query.collision_mask = WORLD_LAYER | ENEMY_LAYER | BOSS_LAYER
	var exclude_list := []
	if player:
		exclude_list.append(player)
	query.exclude = exclude_list
	var hit := space.intersect_ray(query)

	var end_point := origin + dir * max_range
	var hit_node: Node = null
	if not hit.is_empty():
		end_point = hit.position
		hit_node = hit.collider
		_apply_hit(hit_node, hit, dir)

	_spawn_tracer(origin, end_point)
	_spawn_impact(end_point, hit.is_empty())
	_flash()
	_kick = minf(1.0, _kick + 0.55)
	_shake = minf(1.0, _shake + 0.25)

func _apply_hit(hit_node: Node, hit: Dictionary, dir: Vector3) -> void:
	if hit_node == null:
		return
	var target := _resolve_damage_target(hit_node)
	if target == null:
		return
	current_target = target as Node3D
	var dmg := damage
	if target.has_method("is_headshot") and target.is_headshot(hit.position):
		dmg *= headshot_multiplier
	var result: Variant = target.take_damage(dmg, hit.position, dir)
	if result is bool and result:
		emit_signal("hit_confirmed", true)
	else:
		emit_signal("hit_confirmed", false)

func _resolve_damage_target(node: Node) -> Node:
	var current := node
	while current != null:
		if current.has_method("take_damage"):
			return current
		current = current.get_parent()
	return null

func _flash() -> void:
	flash_light.visible = true
	flash_mesh.visible = true
	_flash_timer = 0.055
	flash_mesh.rotation.z = randf() * TAU

func _spawn_tracer(from: Vector3, to: Vector3) -> void:
	if _tracers.is_empty():
		return
	var t: MeshInstance3D = _tracers[_tracer_index]
	_tracer_index = (_tracer_index + 1) % _tracers.size()
	var mid := (from + to) * 0.5
	var dir := to - from
	var length := dir.length()
	if length < 0.05:
		return
	t.visible = true
	t.global_position = mid
	if dir.length_squared() > 0.0001:
		t.look_at(to, Vector3.UP)
	t.scale = Vector3(1.0, 1.0, length)
	var mat := t.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(1.0, 0.9, 0.5, 0.9)
		mat.emission = Color(1.0, 0.8, 0.35)
		mat.emission_energy_multiplier = 6.0
	_create_fade(t, 0.09, true)

func _spawn_impact(pos: Vector3, no_hit: bool) -> void:
	if _impacts.is_empty():
		return
	var idx := int(pos.x * 3.0) % _impacts.size()
	var im: MeshInstance3D = _impacts[idx]
	im.visible = true
	im.global_position = pos
	im.scale = Vector3.ONE * (0.12 if no_hit else 0.2)
	var mat := im.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = Color(1.0, 0.75, 0.35, 0.9) if no_hit else Color(1.0, 0.45, 0.2, 0.9)
		mat.emission = Color(1.0, 0.6, 0.2)
		mat.emission_energy_multiplier = 5.0
	_create_fade(im, 0.22, false)

func _create_fade(node: MeshInstance3D, duration: float, keep_scale: bool) -> void:
	var tw := create_tween()
	tw.tween_property(node, "scale", Vector3.ONE * 0.01 if not keep_scale else node.scale, duration)
	var mat := node.material_override as StandardMaterial3D
	if mat:
		var c := mat.albedo_color
		c.a = 0.0
		tw.parallel().tween_property(mat, "albedo_color", c, duration)
	tw.tween_callback(func() -> void: node.visible = false)

func start_reload() -> void:
	if _reloading or reserve <= 0 or magazine >= mag_size:
		return
	_reloading = true
	_reload_left = reload_time
	GameState.notify("Recargando...", Color(0.7, 0.85, 1.0))

func _finish_reload() -> void:
	_reloading = false
	var need := mag_size - magazine
	var take := mini(need, reserve)
	magazine += take
	reserve -= take
	GameState.set_ammo(magazine, reserve)

func add_ammo(amount: int) -> void:
	reserve = mini(reserve_max, reserve + amount)
	GameState.set_ammo(magazine, reserve)
	GameState.notify("+%d balas" % amount, Color(1.0, 0.85, 0.4))

func is_reloading() -> bool:
	return _reloading
