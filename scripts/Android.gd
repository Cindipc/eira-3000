extends CharacterBody3D

enum Kind { SCOUT, SENTINEL }

const GRAVITY := 20.0
const ATTACK_COOLDOWN := 1.25

@export var kind: int = Kind.SCOUT
@export var max_health := 55.0
@export var move_speed := 3.9
@export var attack_damage := 9.0
@export var attack_range := 2.1
@export var ranged := false
@export var projectile_scene: PackedScene = null
@export var body_height := 1.85

@onready var visual: Node3D = $Visual
@onready var hit_light: OmniLight3D = $HitLight

var health: float = 55.0
var player: Node3D = null
var _cooldown: float = 0.0
var _flash: float = 0.0
var _bob: float = 0.0
var _alerted := false
var _dead := false

func _ready() -> void:
	add_to_group("android")
	health = max_health
	hit_light.visible = false
	collision_layer = 4
	collision_mask = 1

func setup(p_kind: int, p_max_health: float, p_speed: float, p_damage: float, p_ranged: bool) -> void:
	kind = p_kind
	max_health = p_max_health
	health = p_max_health
	move_speed = p_speed
	attack_damage = p_damage
	ranged = p_ranged

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Node3D
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = -1.0

	if _cooldown > 0.0:
		_cooldown -= delta
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.0)
		hit_light.light_energy = _flash * 6.0
		hit_light.visible = _flash > 0.01

	var to_player := player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	var dir := to_player.normalized() if dist > 0.001 else Vector3.ZERO

	var desired := Vector3.ZERO
	if dist <= attack_range and _cooldown <= 0.0:
		_attack(dir, dist)
	elif dist > attack_range * (1.6 if ranged else 1.05):
		desired = dir * move_speed
		_face(dir, delta)
	else:
		_face(dir, delta)

	desired = _steer(desired)
	velocity.x = desired.x
	velocity.z = desired.z
	_separate(delta)

	move_and_slide()
	_animate(delta)

func _steer(desired: Vector3) -> Vector3:
	if desired.length_squared() < 0.0001:
		return desired
	var space := get_world_3d().direct_space_state
	var origin := global_position + Vector3.UP * 1.0
	var fwd := desired.normalized()
	var query := PhysicsRayQueryParameters3D.create(origin, origin + fwd * 2.8)
	query.collision_mask = 1
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		var n: Vector3 = hit.normal
		n.y = 0.0
		if n.length() > 0.01:
			fwd = (fwd + n.normalized() * 2.0).normalized()
	return fwd * move_speed

func _separate(delta: float) -> void:
	var push := Vector3.ZERO
	for other in get_tree().get_nodes_in_group("android"):
		if other == self or not is_instance_valid(other):
			continue
		var d: Vector3 = global_position - (other as Node3D).global_position
		d.y = 0.0
		var l := d.length()
		if l > 0.01 and l < 1.5:
			push += d / l * (1.5 - l)
	if push.length() > 0.0:
		velocity += push.normalized() * 2.0 * delta * 6.0

func _face(dir: Vector3, delta: float) -> void:
	if dir.length_squared() < 0.0001:
		return
	var target_angle := atan2(dir.x, dir.z)
	visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, clampf(delta * 8.0, 0.0, 1.0))

func _animate(delta: float) -> void:
	_bob += delta * (6.0 if velocity.length() > 0.5 else 2.0)
	var amp := 0.045 if velocity.length() > 0.5 else 0.015
	visual.position.y = sin(_bob) * amp
	visual.rotation.x = lerpf(visual.rotation.x, 0.08 if velocity.length() > 0.5 else 0.0, clampf(delta * 6.0, 0.0, 1.0))

func _attack(dir: Vector3, dist: float) -> void:
	_cooldown = ATTACK_COOLDOWN
	if ranged:
		_shoot_projectile(dir)
	else:
		if player.has_method("take_damage"):
			player.take_damage(attack_damage, global_position)
		_melee_flash()

func _shoot_projectile(dir: Vector3) -> void:
	if projectile_scene == null:
		return
	var proj := projectile_scene.instantiate() as Node3D
	get_tree().current_scene.add_child(proj)
	proj.global_position = global_position + Vector3.UP * 1.15 + dir * 0.7
	if proj.has_method("setup"):
		proj.setup(dir, attack_damage, 14.0)
	_muzzle_flash()

func _melee_flash() -> void:
	_flash = 1.0
	hit_light.light_color = Color(1.0, 0.5, 0.2)
	hit_light.visible = true

func _muzzle_flash() -> void:
	_flash = 1.0
	hit_light.light_color = Color(1.0, 0.35, 0.1)
	hit_light.visible = true

func take_damage(amount: float, hit_pos: Vector3 = Vector3.ZERO, _dir: Vector3 = Vector3.ZERO) -> bool:
	if _dead:
		return false
	health -= amount
	_flash = 1.0
	hit_light.light_color = Color(1.0, 0.25, 0.15)
	hit_light.visible = true
	if health <= 0.0:
		_die()
		return true
	return false

func is_headshot(hit_pos: Vector3) -> bool:
	var local := global_transform.affine_inverse() * hit_pos
	return local.y > body_height * 0.78

func _die() -> void:
	_dead = true
	velocity = Vector3.ZERO
	collision_layer = 0
	collision_mask = 0
	remove_from_group("android")
	_spawn_debris()
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector3(0.05, 0.05, 0.05), 0.35)
	tw.parallel().tween_property(self, "position:y", position.y - 0.3, 0.35)
	tw.tween_callback(queue_free)

func _spawn_debris() -> void:
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.45, 0.15)
	light.light_energy = 8.0
	light.omni_range = 9.0
	light.position = global_position + Vector3.UP * 1.0
	get_tree().current_scene.add_child(light)
	var lt := create_tween()
	lt.tween_property(light, "light_energy", 0.0, 0.6)
	lt.tween_callback(light.queue_free)

	for i in 5:
		var piece := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(randf_range(0.1, 0.28), randf_range(0.1, 0.28), randf_range(0.1, 0.28))
		piece.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.25, 0.26, 0.3)
		mat.metallic = 0.8
		mat.roughness = 0.4
		piece.material_override = mat
		piece.position = global_position + Vector3(randf_range(-0.4, 0.4), randf_range(0.4, 1.6), randf_range(-0.4, 0.4))
		get_tree().current_scene.add_child(piece)
		var vel := Vector3(randf_range(-3.0, 3.0), randf_range(2.0, 5.0), randf_range(-3.0, 3.0))
		var pt := create_tween()
		pt.tween_property(piece, "position", piece.position + vel * 0.6, 0.6).set_trans(Tween.TRANS_QUAD)
		pt.tween_property(piece, "position:y", piece.position.y - 1.0, 0.8)
		pt.parallel().tween_property(piece, "scale", Vector3.ZERO, 0.8)
		pt.tween_callback(piece.queue_free)
