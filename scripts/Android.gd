extends CharacterBody3D

enum Kind { SCOUT, SENTINEL }

const GRAVITY := 0.0
const ATTACK_COOLDOWN := 2.2

@export var kind: int = Kind.SCOUT
@export var max_health := 25.0
@export var move_speed := 3.2
@export var attack_damage := 4.0
@export var attack_range := 5.0
@export var ranged := true
@export var projectile_scene: PackedScene = null
@export var body_height := 1.0
## Nivel 3: los androides controlados por Kael cuentan para la mision.
@export var counts_for_mission: bool = false
## Marca visual de androide bajo control de Kael.
@export var controlled: bool = false
## Distancia a la que el androide persigue al jugador (0 = siempre).
@export var aggro_range: float = 0.0

@onready var visual: Node3D = $Visual
@onready var hit_light: OmniLight3D = $HitLight

var health: float = 25.0
var player: Node3D = null
var _cooldown: float = 0.0
var _flash: float = 0.0
var _bob: float = 0.0
var _alerted := false
var _dead := false
var _hover_height := 1.6
var _target_height := 1.6

func _ready() -> void:
	add_to_group("android")
	health = max_health
	if hit_light:
		hit_light.visible = false
	collision_layer = 4
	collision_mask = 1
	_hover_height = global_position.y
	if _hover_height < 1.2:
		_hover_height = 1.6
	_target_height = _hover_height
	if projectile_scene == null:
		var p := load("res://scenes/Projectile.tscn") as PackedScene
		if p:
			projectile_scene = p

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

	if _cooldown > 0.0:
		_cooldown -= delta
	if _flash > 0.0 and hit_light:
		_flash = maxf(0.0, _flash - delta * 4.0)
		hit_light.light_energy = _flash * 6.0
		hit_light.visible = _flash > 0.01

	var to_player := player.global_position - global_position
	var dist := to_player.length()
	var dir := to_player.normalized() if dist > 0.001 else Vector3.ZERO

	if aggro_range > 0.0 and dist > aggro_range:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)
		var target_y := _hover_height + sin(Time.get_ticks_msec() * 0.002) * 0.15
		velocity.y = (target_y - global_position.y) * 2.5
		move_and_slide()
		_animate(delta)
		return

	var desired := Vector3.ZERO
	if dist <= attack_range and _cooldown <= 0.0:
		_attack(dir, dist)
	elif dist > 4.0:
		desired = dir * move_speed
		_face(dir, delta)
	else:
		desired = -dir * (move_speed * 0.6)
		_face(dir, delta)

	desired = _steer(desired)
	velocity.x = desired.x
	velocity.z = desired.z
	# no heavy separation push
	if get_tree().get_nodes_in_group("android").size() > 3:
		var push := Vector3.ZERO
		for other in get_tree().get_nodes_in_group("android"):
			if other == self or not is_instance_valid(other):
				continue
			var d: Vector3 = global_position - (other as Node3D).global_position
			d.y = 0.0
			var l := d.length()
			if l > 0.01 and l < 1.0:
				push += d / l * (1.0 - l)
		if push.length() > 0.0:
			velocity += push.normalized() * 0.8 * delta * 2.0

	var target_y := _hover_height + sin(Time.get_ticks_msec() * 0.002) * 0.15
	var vy := (target_y - global_position.y) * 2.5
	velocity.y = vy

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
	proj.global_position = global_position + Vector3.UP * 0.4 + dir * 0.6
	if proj.has_method("setup"):
		proj.setup(dir, attack_damage, 10.0)
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
	if counts_for_mission:
		var d := get_tree().get_first_node_in_group("l3_director")
		if d and d.has_method("on_controlled_killed"):
			d.call("on_controlled_killed", self)
	_spawn_debris()
	var tw := create_tween()
	tw.tween_property(visual, "scale", Vector3(0.05, 0.05, 0.05), 0.35)
	tw.parallel().tween_property(self, "position:y", position.y - 0.6, 0.35)
	tw.tween_callback(func() -> void:
		queue_free()
		var ld := get_tree().get_first_node_in_group("level_director")
		if ld and ld.has_method("_check_exit"):
			ld.call_deferred("_check_exit"))

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
