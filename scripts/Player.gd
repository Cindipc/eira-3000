extends CharacterBody3D

const GRAVITY := 22.0
const WALK := 3.6
const RUN := 6.2
const CROUCH := 1.7
const JUMP := 8.2
const MOUSE_SENS := 0.0022
const MAX_HEALTH := 100.0
const FIRST_PERSON := false
const CAM_DIST := 4.6
const DEATH_DELAY := 2.0

@onready var visual: Node3D = $Visual
@onready var cam_pivot: Node3D = $CameraPivot
@onready var cam: Camera3D = $CameraPivot/Camera3D
@onready var anim: AnimationPlayer = $Visual/Eira/AnimationPlayer

var speed := WALK
var crouching := false
var pitch := -0.12
var _cam_dist := CAM_DIST
var health: float = MAX_HEALTH
var invuln: float = 0.0
var dead: bool = false
var respawn_point := Vector3.ZERO
var _death_timer: float = 0.0
var _hit_flash: float = 0.0

func _ready() -> void:
	add_to_group("player")
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	for a in anim.get_animation_list():
		var res := anim.get_animation(a)
		if res:
			res.loop_mode = Animation.LOOP_LINEAR
	_set_animation("idle")
	respawn_point = global_position
	if FIRST_PERSON:
		for n in visual.find_children("*", "VisualInstance3D", true, false):
			(n as VisualInstance3D).layers = 2
		cam.cull_mask = 1
	else:
		for n in visual.find_children("*", "VisualInstance3D", true, false):
			(n as VisualInstance3D).layers = 1
		cam.cull_mask = 1 | 2

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and not dead:
		cam_pivot.rotation.y -= event.relative.x * MOUSE_SENS
		pitch = clampf(pitch - event.relative.y * MOUSE_SENS, -0.9, 0.6)
		cam.rotation.x = pitch

func _physics_process(delta: float) -> void:
	if dead:
		_death_timer -= delta
		velocity = velocity.move_toward(Vector3.ZERO, 8.0 * delta)
		move_and_slide()
		if _death_timer <= 0.0:
			_revive()
		return

	if invuln > 0.0:
		invuln -= delta
	if _hit_flash > 0.0:
		_hit_flash = maxf(0.0, _hit_flash - delta * 2.5)
		visual.scale = Vector3.ONE * (1.0 + _hit_flash * 0.06)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	elif velocity.y < 0.0:
		velocity.y = -2.0

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP
		_set_animation("jump")

	crouching = Input.is_action_pressed("crouch")
	if crouching:
		speed = CROUCH
	elif Input.is_action_pressed("run"):
		speed = RUN
	else:
		speed = WALK

	var ix := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var iz := Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	var basis := Basis(Vector3.UP, cam_pivot.rotation.y)
	var dir := basis.x * ix + (-basis.z) * iz
	if dir.length_squared() > 0.001:
		dir = dir.normalized()
		velocity.x = dir.x * speed
		velocity.z = dir.z * speed
		visual.rotation.y = lerp_angle(visual.rotation.y, atan2(dir.x, dir.z), delta * 12.0)
		if is_on_floor():
			_set_animation("run" if speed == RUN else "walk")
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)
		if is_on_floor():
			_set_animation("idle")
	if not is_on_floor():
		_set_animation("jump")

	move_and_slide()
	_update_camera(delta)

func _update_camera(delta: float) -> void:
	if FIRST_PERSON:
		cam.position = Vector3.ZERO
		return
	var pivot := cam_pivot.global_position
	var back := cam_pivot.global_transform.basis.z
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(pivot, pivot + back * CAM_DIST)
	query.exclude = [self]
	query.collision_mask = 1
	var hit := space.intersect_ray(query)
	var target := CAM_DIST
	if not hit.is_empty():
		target = maxf(pivot.distance_to(hit.position) - 0.3, 1.0)
	_cam_dist = lerpf(_cam_dist, target, clampf(12.0 * delta, 0.0, 1.0))
	cam.position = Vector3(0, 0, _cam_dist)

func _set_animation(name: String) -> void:
	if anim and anim.has_animation(name) and anim.current_animation != name:
		anim.play(name, 0.2)

func take_damage(amount: float, _from: Vector3 = Vector3.ZERO) -> void:
	if dead or invuln > 0.0:
		return
	health = maxf(0.0, health - amount)
	invuln = 0.45
	_hit_flash = 1.0
	GameState.set_health(health, MAX_HEALTH)
	GameState.notify("Daño recibido: -%d" % int(amount), Color(1.0, 0.35, 0.35))
	if health <= 0.0:
		_die()

func heal(amount: float) -> void:
	if dead:
		return
	health = minf(MAX_HEALTH, health + amount)
	GameState.set_health(health, MAX_HEALTH)

func _die() -> void:
	dead = true
	_death_timer = DEATH_DELAY
	_set_animation("idle")
	GameState.notify("Eira ha sido neutralizada. Reconstruyendo protocolo...", Color(1.0, 0.25, 0.3))
	GameState.set_prompt("")

func _revive() -> void:
	dead = false
	health = MAX_HEALTH
	invuln = 2.0
	global_position = respawn_point
	velocity = Vector3.ZERO
	GameState.set_health(health, MAX_HEALTH)
	GameState.notify("Protocolo restaurado en el último punto de control", Color(0.4, 1.0, 0.8))

func set_respawn_point(p: Vector3) -> void:
	respawn_point = p
